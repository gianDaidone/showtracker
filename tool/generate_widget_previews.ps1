# Anteprime dimostrative originali: nessun poster remoto o dato personale.
# Rigenera su Windows: powershell -NoProfile -File tool/generate_widget_previews.ps1
param([string]$OutputDirectory = "$PSScriptRoot/../android/app/src/main/res/drawable-nodpi")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
[System.IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null

function Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Brush([string]$hex) { [System.Drawing.SolidBrush]::new((Color $hex)) }
function RoundPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$radius) {
    $p = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $radius * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc(($x + $w - $d), $y, $d, $d, 270, 90)
    $p.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0, 90)
    $p.AddArc($x, ($y + $h - $d), $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}
function Rounded($g, [string]$hex, $x, $y, $w, $h, $radius) {
    $p = RoundPath $x $y $w $h $radius
    $b = Brush $hex
    try { $g.FillPath($b, $p) } finally { $p.Dispose(); $b.Dispose() }
}
function Text($g, [string]$value, [float]$size, [string]$hex, $x, $y, [bool]$bold = $false) {
    $style = [System.Drawing.FontStyle]::Regular
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold }
    $font = [System.Drawing.Font]::new('Segoe UI', $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
    $b = Brush $hex
    try { $g.DrawString($value, $font, $b, [float]$x, [float]$y) }
    finally { $font.Dispose(); $b.Dispose() }
}
function Scene([bool]$alternate) {
    $bmp = [System.Drawing.Bitmap]::new(720, 720)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $top = '#182944'; $bottom = '#66404F'; $moon = '#F2C783'
    if ($alternate) { $top = '#162C35'; $bottom = '#3E6965'; $moon = '#F0D9AE' }
    $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 0, 720, 720), (Color $top), (Color $bottom), 90.0)
    $g.FillRectangle($gradient, 0, 0, 720, 720)
    $gradient.Dispose()
    $light = Brush $moon
    $g.FillEllipse($light, 438, 104, 124, 124)
    $light.Dispose()
    $star = Brush '#C9D1DD'
    foreach ($pos in @(@(88,112), @(182,62), @(310,164), @(610,82), @(646,258), @(246,240))) {
        $g.FillEllipse($star, [float]$pos[0], [float]$pos[1], 4.0, 4.0)
    }
    $star.Dispose()
    $far = Brush '#293349'; $near = Brush '#172133'; $front = Brush '#101722'
    $g.FillPolygon($far, [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(0,430), [System.Drawing.Point]::new(210,235),
        [System.Drawing.Point]::new(450,455), [System.Drawing.Point]::new(625,290),
        [System.Drawing.Point]::new(720,405), [System.Drawing.Point]::new(720,720),
        [System.Drawing.Point]::new(0,720)))
    $g.FillPolygon($near, [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(0,500), [System.Drawing.Point]::new(328,330),
        [System.Drawing.Point]::new(720,575), [System.Drawing.Point]::new(720,720),
        [System.Drawing.Point]::new(0,720)))
    $g.FillPolygon($front, [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(0,630), [System.Drawing.Point]::new(155,525),
        [System.Drawing.Point]::new(530,620), [System.Drawing.Point]::new(720,500),
        [System.Drawing.Point]::new(720,720), [System.Drawing.Point]::new(0,720)))
    $far.Dispose(); $near.Dispose(); $front.Dispose()
    $g.Dispose()
    return $bmp
}
function SavePng($image, [string]$name) {
    $image.Save([System.IO.Path]::GetFullPath("$OutputDirectory/$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
}

$scene = Scene $false
$alternate = Scene $true
try {
    SavePng $scene 'widget_preview_scene'
    SavePng $alternate 'widget_preview_scene_alt'

    $watching = [System.Drawing.Bitmap]::new(480, 480)
    $g = [System.Drawing.Graphics]::FromImage($watching)
    try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $clip = RoundPath 0 0 480 480 32
        $g.SetClip($clip); $clip.Dispose()
        $g.DrawImage($scene, 0, 0, 480, 480)
        Rounded $g '#E68A00' 28 26 166 40 12
        Text $g 'Da Vedere' 24 '#FFFFFF' 39 29 $true
        Text $g 'Serie di esempio' 29 '#FFFFFF' 28 369 $true
        Text $g 'S01 E03' 23 '#BFC4D0' 28 414
        Rounded $g '#E68A00' 383 383 68 68 34
        $pen = [System.Drawing.Pen]::new((Color '#FFFFFF'), 4)
        $g.DrawLine($pen, 405, 417, 431, 417)
        $g.DrawLine($pen, 420, 406, 431, 417)
        $g.DrawLine($pen, 420, 428, 431, 417)
        $pen.Dispose()
        SavePng $watching 'widget_maratona_preview'
    } finally { $g.Dispose(); $watching.Dispose() }

    $upcoming = [System.Drawing.Bitmap]::new(840, 420)
    $g = [System.Drawing.Graphics]::FromImage($upcoming)
    try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        Rounded $g '#1E1E2E' 0 0 840 420 32
        Text $g 'In Uscita' 26 '#FFFFFF' 28 19 $true
        for ($i = 0; $i -lt 2; $i++) {
            $x = 28 + $i * 402
            $clip = RoundPath $x 68 382 214 16
            $g.SetClip($clip); $clip.Dispose()
            $art = $scene
            if ($i -eq 1) { $art = $alternate }
            $g.DrawImage($art, [System.Drawing.Rectangle]::new($x, 68, 382, 214),
                [System.Drawing.Rectangle]::new(0, 0, 720, 500), [System.Drawing.GraphicsUnit]::Pixel)
            $g.ResetClip()
            Rounded $g '#E68A00' ($x + 12) 238 82 30 8
            $date = '12 nov'; $title = 'Serie di esempio'; $episode = 'S01 E04'; $countdown = 'Domani'
            if ($i -eq 1) { $date = '14 nov'; $title = 'Una nuova avventura'; $episode = 'S02 E01'; $countdown = 'Tra 3 giorni' }
            Text $g $date 18 '#FFFFFF' ($x + 21) 240 $true
            Text $g $title 25 '#FFFFFF' $x 294 $true
            Text $g $episode 21 '#A3A3B8' $x 335
            Text $g $countdown 21 '#A3A3B8' $x 368
        }
        SavePng $upcoming 'widget_prossimamente_preview'
    } finally { $g.Dispose(); $upcoming.Dispose() }
} finally { $scene.Dispose(); $alternate.Dispose() }
