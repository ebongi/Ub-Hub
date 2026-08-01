# Implementation Plan - Robust Payment Polling & Network Resilience

This plan addresses the `SocketException` (Failed host lookup) occurring during payment status polling. We will make the polling mechanism "Network Aware" to prevent log flooding and handle temporary connectivity drops gracefully.

## Proposed Changes

### 1. Service Layer Resilience

#### [MODIFY] [FapshiService](file:///home/joviallaps/Desktop/Ub-Hub/lib/services/fapshi_service.dart)
- Update `checkPaymentStatus` to catch `SocketException` and throw a custom `NetworkException`.
- Update `waitForSuccessfulPayment` to:
    - Use the `connectivity_plus` package to check if the device is online before each poll.
    - If a network error occurs, **increase the retry interval** (Exponential Backoff) to avoid spamming the logs and draining the battery.
    - Return a specific `PaymentStatus.networkError` or handle it silently in the background.

### 2. UI Layer Improvements

#### [MODIFY] [SubscriptionPlansScreen](file:///home/joviallaps/Desktop/Ub-Hub/lib/Screens/UI/preview/Settings/subscription_plans_screen.dart)
- Show a clearer "Waiting for Internet..." message if the polling fails due to connection.
- Ensure the `_isProcessing` state doesn't get stuck if the network is permanently down.

## Verification Plan

### Manual Verification
1. Start a payment process (Trigger the browser fallback).
2. Turn off Wi-Fi/Data on the device.
3. Observe the logs: It should stop spamming `SocketException` and wait for connectivity.
4. Turn Wi-Fi/Data back on.
5. Verify the app resumes polling and detects the successful payment once completed.
