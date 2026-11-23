param(
    [int]$Port = 8000
)

$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Output "Serving $root at http://127.0.0.1:$Port/"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath)
    if ($requestPath -eq "/") {
        $requestPath = "/index.html"
    }

    $relativePath = $requestPath.TrimStart("/")
    $filePath = [System.IO.Path]::GetFullPath((Join-Path $root $relativePath))
    $rootPath = [System.IO.Path]::GetFullPath($root).TrimEnd("\") + "\"

    if (-not $filePath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        $context.Response.StatusCode = 404
        $context.Response.Close()
        continue
    }

    $extension = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
    $mimeTypes = @{
        ".html" = "text/html; charset=utf-8"
        ".css" = "text/css; charset=utf-8"
        ".js" = "application/javascript; charset=utf-8"
        ".m4a" = "audio/mp4"
        ".mp4" = "video/mp4"
        ".jpeg" = "image/jpeg"
        ".jpg" = "image/jpeg"
        ".png" = "image/png"
        ".svg" = "image/svg+xml"
    }
    $context.Response.ContentType = $mimeTypes[$extension]
    if (-not $context.Response.ContentType) {
        $context.Response.ContentType = "application/octet-stream"
    }

    $bytes = [IO.File]::ReadAllBytes($filePath)
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
}
