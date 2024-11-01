import 'dart:async';
import 'dart:convert';

import 'package:agritechv2/config/router.dart';
import 'package:agritechv2/models/transaction/OrderItems.dart';
import 'package:agritechv2/models/transaction/PaymentMethod.dart';
import 'package:agritechv2/models/transaction/TransactionStatus.dart';
import 'package:agritechv2/models/transaction/Transactions.dart';
import 'package:agritechv2/models/users/Customer.dart';
import 'package:agritechv2/repository/transaction_repository.dart';
import 'package:agritechv2/styles/color_styles.dart';
import 'package:agritechv2/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Import this for Timer
import 'dart:async'; // Import this for Timer

class TransactionsContainer extends StatefulWidget {
  final Transactions transactions;
  final Customer customer;

  const TransactionsContainer({
    super.key,
    required this.transactions,
    required this.customer,
  });

  @override
  _TransactionsContainerState createState() => _TransactionsContainerState();
}

class _TransactionsContainerState extends State<TransactionsContainer> {
  Timer? _cancelTimer;
  Duration? _remainingTime; // To keep track of the remaining time
  bool _isCancelled = false; // To track if the order is canceled

  @override
  void initState() {
    super.initState();
    // Calculate remaining time based on createdAt
    _calculateRemainingTime();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final createdAt = widget
        .transactions.createdAt; // Assuming createdAt is a DateTime object
    final elapsedTime = now.difference(createdAt);

    if (widget.transactions.payment.status == PaymentStatus.UNPAID &&
        widget.transactions.payment.type == PaymentType.GCASH) {
      final totalDuration = const Duration(minutes: 10);
      _remainingTime = totalDuration - elapsedTime;

      // If the elapsed time exceeds the total duration, cancel the order
      if (_remainingTime!.inSeconds <= 0) {
        _cancelOrder();
      } else {
        // Start a timer to update the remaining time every second
        _startCancelTimer();
      }
    }
  }

  void _startCancelTimer() {
    _cancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime!.inSeconds <= 0) {
          _cancelOrder();
          timer.cancel();
        } else {
          _remainingTime = Duration(seconds: _remainingTime!.inSeconds - 1);
        }
      });
    });
  }

  void _cancelOrder() {
    if (_isCancelled ||
        widget.transactions.status == TransactionStatus.CANCELLED) {
      // Prevent further cancellations if already canceled
      return;
    }

    // Logic to cancel the order
    context
        .read<TransactionRepostory>()
        .cancelTrancsaction(
          widget.transactions.id,
          widget.customer.name,
          "Order cancelled due to unpaid order",
        )
        .then((_) {
      // If the cancellation was successful, update the UI
      setState(() {
        widget.transactions.status = TransactionStatus
            .CANCELLED; // Update the transaction status to CANCELLED
        _isCancelled = true; // Mark the order as canceled
        _remainingTime = Duration.zero; // Reset the timer
      });

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order has been automatically canceled")),
      );
    }).catchError((error) {
      // Handle any errors that occur during cancellation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel order: $error")),
      );
    });
  }

  @override
  void dispose() {
    _cancelTimer?.cancel(); // Cancel the timer if the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push("/view-order/${widget.transactions.id}"),
      child: Container(
        color: Colors.white,
        width: double.infinity,
        padding: const EdgeInsets.all(10.0),
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.transactions.payment.status == PaymentStatus.PAID &&
                    widget.transactions.payment.type == PaymentType.GCASH)
                  const Text(
                    "Paid via GCASH",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                const Text(""),
                Text(widget.transactions.status.name.replaceAll("_", " ")),
              ],
            ),
            Container(
              width: double.infinity,
              color: Colors.grey[100],
              margin: const EdgeInsets.all(5.0),
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('hh:mm a')
                        .format(widget.transactions.details.last.updatedAt),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.transactions.details.last.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.transactions.orderList.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final OrderItems items = widget.transactions.orderList[index];
                return ListTile(
                  leading: Image.network(
                    items.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  title: Text(items.productName),
                  subtitle: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPrice(items.price * items.quantity),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "x${items.quantity}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Total : ${formatPrice(widget.transactions.payment.amount)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.transactions.status == TransactionStatus.COMPLETED)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorStyle.brandGreen,
                    ),
                    onPressed: () {
                      context.push('/rate', extra: widget.transactions);
                    },
                    child: const Text(
                      'Rate',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            if (widget.transactions.status == TransactionStatus.PENDING)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorStyle.brandRed,
                      ),
                      onPressed: () {
                        context.push('/cancel', extra: widget.transactions);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (widget.transactions.payment.status ==
                      PaymentStatus.UNPAID)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorStyle.brandGreen,
                        ),
                        onPressed: () {
                          context.push('/gcash-payment', extra: {
                            'transactionID': widget.transactions.id,
                            'payment': jsonEncode(widget.transactions.payment),
                            'customer': widget.customer.name
                          });
                        },
                        child: const Text(
                          'Pay now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            // Display the countdown timer
            if (widget.transactions.payment.status == PaymentStatus.UNPAID &&
                widget.transactions.payment.type == PaymentType.GCASH &&
                !_isCancelled)
              Container(
                width: double.infinity,
                color: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Pay now or your order will be canceled. Time remaining: ${_formatDuration(_remainingTime ?? Duration.zero)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Optional: Highlight the timer in red
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
