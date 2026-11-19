<?php
/**
 * GET / POST /api/customer/payu/failure
 */
$txnid = $_REQUEST['txnid'] ?? '';
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Failed</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 40px 20px; background: #FFF5F5; }
    .card { background: #ffffff; border-radius: 16px; padding: 30px; box-shadow: 0 10px 25px rgba(0,0,0,0.08); max-width: 400px; margin: 0 auto; }
    .btn { display: inline-block; background-color: #EF4444; color: #ffffff; padding: 12px 24px; border-radius: 10px; text-decoration: none; font-weight: bold; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="card">
    <h2>Payment Failed or Cancelled</h2>
    <p>Transaction ID: <?php echo htmlspecialchars($txnid); ?></p>
    <a href="hungrily://payment_failure?txnid=<?php echo urlencode($txnid); ?>" class="btn">Return to App</a>
  </div>
  <script>
    setTimeout(function() {
      window.location.href = "hungrily://payment_failure?txnid=<?php echo urlencode($txnid); ?>";
    }, 500);
  </script>
</body>
</html>
