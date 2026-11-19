<?php
/**
 * GET / POST /api/customer/payu/success
 * Handles PayU success redirect and returns HTML auto-redirect to app scheme.
 */
$txnid  = $_REQUEST['txnid'] ?? $_REQUEST['mihpayid'] ?? '';
$status = $_REQUEST['status'] ?? 'success';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Successful</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 40px 20px; background: #FAF5FF; color: #1A1A2E; }
    .card { background: #ffffff; border-radius: 16px; padding: 30px; box-shadow: 0 10px 25px rgba(0,0,0,0.08); max-width: 400px; margin: 0 auto; }
    .icon { font-size: 54px; color: #10B981; margin-bottom: 16px; }
    .btn { display: inline-block; background-color: #F58220; color: #ffffff; padding: 12px 24px; border-radius: 10px; text-decoration: none; font-weight: bold; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✓</div>
    <h2>Payment Successful!</h2>
    <p>Transaction ID: <strong><?php echo htmlspecialchars($txnid); ?></strong></p>
    <p>Redirecting back to Hungrily Foods...</p>
    <a href="hungrily://payment_success?txnid=<?php echo urlencode($txnid); ?>&status=success" class="btn">Return to App</a>
  </div>
  <script>
    setTimeout(function() {
      window.location.href = "hungrily://payment_success?txnid=<?php echo urlencode($txnid); ?>&status=success";
    }, 500);
  </script>
</body>
</html>
