Add-Type -AssemblyName System.Net
Add-Type -AssemblyName System.Web
$listener = New-Object System.Net.HttpListener
$prefix = 'http://localhost:8000/'
if (-not $listener.Prefixes.Contains($prefix)) { $listener.Prefixes.Add($prefix) }
$listener.Start()
Write-Host "Serving $pwd at $prefix"
while ($true) {
  try {
    $context = $listener.GetContext()
    $req = $context.Request
    $path = [System.Web.HttpUtility]::UrlDecode($req.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($path)) { $path = 'game_over_preview.html' }
    $full = Join-Path -Path (Get-Location) -ChildPath $path
    if (-not (Test-Path $full)) {
      $context.Response.StatusCode = 404
      $bytes = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
      $context.Response.OutputStream.Write($bytes,0,$bytes.Length)
      $context.Response.Close()
      continue
    }
    $ext = [System.IO.Path]::GetExtension($full)
    $mime = switch ($ext) {
      '.html' { 'text/html' }
      '.css'  { 'text/css' }
      '.js'   { 'application/javascript' }
      default { 'application/octet-stream' }
    }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $context.Response.ContentType = $mime
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes,0,$bytes.Length)
    $context.Response.Close()
  } catch {
    Write-Host "Server error: $_" -ForegroundColor Red
  }
}