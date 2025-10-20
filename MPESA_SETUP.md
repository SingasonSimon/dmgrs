# M-Pesa Daraja API Setup Guide

## 1. Get Your Credentials

### Register at Safaricom Developer Portal
1. Go to: https://developer.safaricom.co.ke/
2. Create account and register your app
3. Get your credentials:
   - Consumer Key
   - Consumer Secret
   - Business Short Code (for production)
   - Passkey (for production)

## 2. Update Constants

Replace the placeholder values in `lib/utils/constants.dart`:

```dart
// Replace these with your actual credentials
static const String mpesaConsumerKey = 'YOUR_ACTUAL_CONSUMER_KEY';
static const String mpesaConsumerSecret = 'YOUR_ACTUAL_CONSUMER_SECRET';
static const String mpesaCallbackUrl = 'https://your-domain.com/mpesa/callback';
```

## 3. Test with Sandbox

The app is currently configured for **sandbox mode** which is perfect for testing:

- **Sandbox Business Short Code**: `174379`
- **Sandbox Passkey**: Already configured
- **Test Phone Numbers**: Use any Kenyan phone number format (07XX XXX XXX)

## 4. Production Setup

When ready for production:

1. **Update Constants:**
```dart
// Switch to production URL
static const String mpesaSandboxUrl = 'https://api.safaricom.co.ke'; // Production
static const String mpesaBusinessShortCode = 'YOUR_PRODUCTION_SHORT_CODE';
static const String mpesaPasskey = 'YOUR_PRODUCTION_PASSKEY';
```

2. **Set up Callback URL:**
   - Create a webhook endpoint to receive payment confirmations
   - Update `mpesaCallbackUrl` with your actual domain

## 5. Testing the Integration

### Test Contribution Payment:
1. Go to Contributions tab
2. Tap "Make Contribution"
3. Enter a test phone number (07XX XXX XXX)
4. Tap "Pay Now"
5. You should see "Payment initiated! Check your phone for M-Pesa prompt."

### Test Loan Payment:
1. Go to Loans tab
2. Tap on an active loan
3. Tap "Pay Now" on any payment
4. Enter phone number and confirm
5. Check for M-Pesa prompt

## 6. Payment Flow

1. **User initiates payment** → App calls M-Pesa STK Push
2. **M-Pesa sends prompt** → User enters PIN on phone
3. **Payment processed** → M-Pesa sends callback to your server
4. **Status updated** → App reflects payment status

## 7. Callback Handling (Advanced)

For production, you'll need to handle M-Pesa callbacks:

```dart
// Example callback handler
static void handleMpesaCallback(Map<String, dynamic> callbackData) {
  final processed = MpesaService.processCallback(callbackData);
  
  if (processed['success']) {
    // Update payment status in Firestore
    // Send notification to user
    // Update loan/contribution status
  }
}
```

## 8. Security Notes

- Never commit real credentials to version control
- Use environment variables for production
- Implement proper callback URL validation
- Add request signing for production callbacks

## 9. Common Issues

### "Failed to get access token"
- Check your Consumer Key and Secret
- Ensure you're using the correct environment (sandbox/production)

### "STK Push failed"
- Verify phone number format (should be 07XX XXX XXX)
- Check if you have sufficient test balance (sandbox)
- Ensure callback URL is accessible

### "Payment not reflecting"
- Check callback URL is working
- Verify Firestore security rules
- Check app logs for errors

## 10. Next Steps

1. **Get your credentials** from Safaricom Developer Portal
2. **Update constants** with real values
3. **Test with sandbox** using test phone numbers
4. **Set up callback URL** for production
5. **Deploy and test** with real users

## Support

For M-Pesa API issues:
- Safaricom Developer Portal: https://developer.safaricom.co.ke/
- Documentation: https://developer.safaricom.co.ke/docs
- Support: developer@safaricom.co.ke
