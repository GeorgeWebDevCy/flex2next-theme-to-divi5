param(
	[string]$OutputPath = (Join-Path $PSScriptRoot '..\flex2next-divi-child\screenshot.png')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase

function New-HexColor {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Hex,

		[byte]$Alpha = 255
	)

	$normalized = $Hex.TrimStart('#')
	if ($normalized.Length -ne 6) {
		throw "Expected a 6-digit hex color, got '$Hex'."
	}

	return [System.Windows.Media.Color]::FromArgb(
		$Alpha,
		[Convert]::ToByte($normalized.Substring(0, 2), 16),
		[Convert]::ToByte($normalized.Substring(2, 2), 16),
		[Convert]::ToByte($normalized.Substring(4, 2), 16)
	)
}

function New-SolidBrush {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Hex,

		[byte]$Alpha = 255
	)

	$brush = [System.Windows.Media.SolidColorBrush]::new((New-HexColor -Hex $Hex -Alpha $Alpha))
	$brush.Freeze()
	return $brush
}

function New-Pen {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Hex,

		[double]$Thickness = 1,

		[byte]$Alpha = 255
	)

	$pen = [System.Windows.Media.Pen]::new((New-SolidBrush -Hex $Hex -Alpha $Alpha), $Thickness)
	$pen.Freeze()
	return $pen
}

function New-Typeface {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Family,

		[string]$Weight = 'Normal'
	)

	$fontWeight = switch ($Weight) {
		'Bold' { [System.Windows.FontWeights]::Bold; break }
		'SemiBold' { [System.Windows.FontWeights]::SemiBold; break }
		'Light' { [System.Windows.FontWeights]::Light; break }
		default { [System.Windows.FontWeights]::Normal }
	}

	return [System.Windows.Media.Typeface]::new(
		[System.Windows.Media.FontFamily]::new($Family),
		[System.Windows.FontStyles]::Normal,
		$fontWeight,
		[System.Windows.FontStretches]::Normal
	)
}

function New-FormattedText {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Text,

		[double]$Size,

		[System.Windows.Media.Brush]$Brush,

		[string]$Weight = 'Normal'
	)

	return [System.Windows.Media.FormattedText]::new(
		$Text,
		[System.Globalization.CultureInfo]::InvariantCulture,
		[System.Windows.FlowDirection]::LeftToRight,
		(New-Typeface -Family 'Segoe UI' -Weight $Weight),
		$Size,
		$Brush,
		1.0
	)
}

function Draw-TextBlock {
	param(
		[Parameter(Mandatory = $true)]
		[System.Windows.Media.DrawingContext]$Context,

		[Parameter(Mandatory = $true)]
		[string]$Text,

		[double]$X,
		[double]$Y,
		[double]$Width,
		[double]$Size,
		[System.Windows.Media.Brush]$Brush,
		[string]$Weight = 'Normal',
		[double]$LineHeight = 1.15
	)

	$formatted = New-FormattedText -Text $Text -Size $Size -Brush $Brush -Weight $Weight
	$formatted.MaxTextWidth = $Width
	$Context.DrawText($formatted, [System.Windows.Point]::new($X, $Y))
	return $formatted.Height
}

function Draw-Mark {
	param(
		[Parameter(Mandatory = $true)]
		[System.Windows.Media.DrawingContext]$Context,

		[double]$X,
		[double]$Y,
		[double]$Size,
		[System.Windows.Media.Brush]$ForegroundBrush,
		[System.Windows.Media.Brush]$BackgroundBrush,
		[System.Windows.Media.Pen]$BorderPen
	)

	$Context.DrawRoundedRectangle(
		$BackgroundBrush,
		$BorderPen,
		[System.Windows.Rect]::new($X, $Y, $Size, $Size),
		[math]::Round($Size * 0.205),
		[math]::Round($Size * 0.205)
	)

	$iconScale = ($Size * 0.74) / 180.0
	$iconOffset = $Size * 0.13

	$transformGroup = [System.Windows.Media.TransformGroup]::new()
	$transformGroup.Children.Add([System.Windows.Media.ScaleTransform]::new($iconScale, $iconScale))
	$transformGroup.Children.Add([System.Windows.Media.TranslateTransform]::new($X + $iconOffset, $Y + $iconOffset))
	$Context.PushTransform($transformGroup)
	$Context.DrawGeometry($ForegroundBrush, $null, $script:MarkPathTop)
	$Context.DrawGeometry($ForegroundBrush, $null, $script:MarkPathBottom)
	$Context.Pop()
}

$script:MarkPathTop = [System.Windows.Media.Geometry]::Parse('M101.141 53H136.632C151.023 53 162.689 64.6662 162.689 79.0573V112.904H148.112V79.0573C148.112 78.7105 148.098 78.3662 148.072 78.0251L112.581 112.898C112.701 112.902 112.821 112.904 112.941 112.904H148.112V126.672H112.941C98.5504 126.672 86.5638 114.891 86.5638 100.5V66.7434H101.141V100.5C101.141 101.15 101.191 101.792 101.289 102.422L137.56 66.7816C137.255 66.7563 136.945 66.7434 136.632 66.7434H101.141V53Z')
$script:MarkPathBottom = [System.Windows.Media.Geometry]::Parse('M65.2926 124.136L14 66.7372H34.6355L64.7495 100.436V66.7372H80.1365V118.47C80.1365 126.278 70.4953 129.958 65.2926 124.136Z')
$script:MarkPathTop.Freeze()
$script:MarkPathBottom.Freeze()

$width = 1200
$height = 900

$black = New-SolidBrush -Hex '050505'
$white = New-SolidBrush -Hex 'FAFAFA'
$softWhite = New-SolidBrush -Hex 'FAFAFA' -Alpha 168
$subtleWhite = New-SolidBrush -Hex 'FAFAFA' -Alpha 112
$faintWhite = New-SolidBrush -Hex 'FAFAFA' -Alpha 72
$linePen = New-Pen -Hex 'FAFAFA' -Alpha 28
$lightLinePen = New-Pen -Hex '000000' -Alpha 18
$lightText = New-SolidBrush -Hex '111111'
$mutedDark = New-SolidBrush -Hex '111111' -Alpha 150
$lightFill = New-SolidBrush -Hex 'F2F2F2'
$cardFill = New-SolidBrush -Hex 'FFFFFF' -Alpha 9
$cardBorder = New-Pen -Hex 'FAFAFA' -Alpha 20

$backgroundBrush = [System.Windows.Media.LinearGradientBrush]::new(
	(New-HexColor -Hex '020202'),
	(New-HexColor -Hex '171717'),
	[System.Windows.Point]::new(0, 0),
	[System.Windows.Point]::new(1, 1)
)
$backgroundBrush.Freeze()

$headerBrush = New-SolidBrush -Hex '050505' -Alpha 176
$pillBrush = $white
$pillText = $black

$orbLeft = [System.Windows.Media.RadialGradientBrush]::new()
$orbLeft.GradientOrigin = [System.Windows.Point]::new(0.5, 0.5)
$orbLeft.Center = [System.Windows.Point]::new(0.5, 0.5)
$orbLeft.RadiusX = 0.5
$orbLeft.RadiusY = 0.5
$orbLeft.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-HexColor -Hex 'FFFFFF' -Alpha 38), 0.0))
$orbLeft.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-HexColor -Hex 'FFFFFF' -Alpha 0), 1.0))
$orbLeft.Freeze()

$orbRight = [System.Windows.Media.RadialGradientBrush]::new()
$orbRight.GradientOrigin = [System.Windows.Point]::new(0.5, 0.5)
$orbRight.Center = [System.Windows.Point]::new(0.5, 0.5)
$orbRight.RadiusX = 0.5
$orbRight.RadiusY = 0.5
$orbRight.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-HexColor -Hex 'FFFFFF' -Alpha 22), 0.0))
$orbRight.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-HexColor -Hex 'FFFFFF' -Alpha 0), 1.0))
$orbRight.Freeze()

$visual = [System.Windows.Media.DrawingVisual]::new()
$context = $visual.RenderOpen()

$context.DrawRectangle($backgroundBrush, $null, [System.Windows.Rect]::new(0, 0, $width, $height))
$context.DrawEllipse($orbLeft, $null, [System.Windows.Point]::new(160, 120), 210, 210)
$context.DrawEllipse($orbRight, $null, [System.Windows.Point]::new(1040, 760), 180, 180)

$context.DrawRoundedRectangle($headerBrush, $linePen, [System.Windows.Rect]::new(32, 28, 1136, 74), 24, 24)
Draw-Mark -Context $context -X 56 -Y 41 -Size 46 -ForegroundBrush $white -BackgroundBrush (New-SolidBrush -Hex '000000') -BorderPen $null
[void](Draw-TextBlock -Context $context -Text 'Flex2 Ai' -X 116 -Y 45 -Width 180 -Size 22 -Brush $white -Weight 'SemiBold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'Philosophy    Workflows    Benefits' -X 752 -Y 49 -Width 270 -Size 14 -Brush $subtleWhite -Weight 'Normal' -LineHeight 1.0)
$context.DrawRoundedRectangle($pillBrush, $null, [System.Windows.Rect]::new(1026, 42, 116, 46), 23, 23)
[void](Draw-TextBlock -Context $context -Text 'Consultation' -X 1048 -Y 55 -Width 84 -Size 13 -Brush $pillText -Weight 'SemiBold' -LineHeight 1.0)

[void](Draw-TextBlock -Context $context -Text 'FLEX2 AI PARADIGM' -X 72 -Y 150 -Width 260 -Size 14 -Brush $subtleWhite -Weight 'SemiBold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text "Invisible`nIntelligence." -X 72 -Y 182 -Width 470 -Size 76 -Brush $white -Weight 'Bold' -LineHeight 0.98)
[void](Draw-TextBlock -Context $context -Text 'We build invisible automation that removes manual bottlenecks, reduces operational drag, and compounds savings across your entire workflow.' -X 74 -Y 380 -Width 520 -Size 21 -Brush $softWhite -Weight 'Light' -LineHeight 1.35)
$context.DrawRoundedRectangle($pillBrush, $null, [System.Windows.Rect]::new(74, 486, 178, 54), 27, 27)
[void](Draw-TextBlock -Context $context -Text 'Initiate Evolution' -X 100 -Y 503 -Width 132 -Size 15 -Brush $pillText -Weight 'SemiBold' -LineHeight 1.0)
$context.DrawRoundedRectangle($cardFill, $cardBorder, [System.Windows.Rect]::new(268, 486, 152, 54), 27, 27)
[void](Draw-TextBlock -Context $context -Text 'Global Header + Footer' -X 291 -Y 503 -Width 110 -Size 13 -Brush $white -Weight 'Normal' -LineHeight 1.0)

$context.DrawRoundedRectangle((New-SolidBrush -Hex 'FFFFFF' -Alpha 7), $cardBorder, [System.Windows.Rect]::new(696, 148, 432, 386), 34, 34)
$context.DrawEllipse((New-SolidBrush -Hex 'FFFFFF' -Alpha 10), $null, [System.Windows.Point]::new(912, 340), 130, 130)
Draw-Mark -Context $context -X 806 -Y 230 -Size 212 -ForegroundBrush $black -BackgroundBrush $white -BorderPen $null
[void](Draw-TextBlock -Context $context -Text 'Enterprise automation that looks native inside Divi.' -X 752 -Y 460 -Width 320 -Size 18 -Brush $softWhite -Weight 'Light' -LineHeight 1.3)

$context.DrawRoundedRectangle((New-SolidBrush -Hex 'FFFFFF' -Alpha 7), $cardBorder, [System.Windows.Rect]::new(72, 588, 1056, 84), 28, 28)
[void](Draw-TextBlock -Context $context -Text '99%' -X 118 -Y 610 -Width 80 -Size 34 -Brush $white -Weight 'Bold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'time saved' -X 118 -Y 646 -Width 120 -Size 13 -Brush $subtleWhite -Weight 'Normal' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text '24/7' -X 392 -Y 610 -Width 80 -Size 34 -Brush $white -Weight 'Bold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'continuous output' -X 392 -Y 646 -Width 150 -Size 13 -Brush $subtleWhite -Weight 'Normal' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text '63%' -X 700 -Y 610 -Width 80 -Size 34 -Brush $white -Weight 'Bold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'overhead reduction' -X 700 -Y 646 -Width 160 -Size 13 -Brush $subtleWhite -Weight 'Normal' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'Stability' -X 968 -Y 618 -Width 120 -Size 22 -Brush $white -Weight 'SemiBold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'Fewer manual touchpoints, fewer failures.' -X 968 -Y 648 -Width 118 -Size 12 -Brush $subtleWhite -Weight 'Normal' -LineHeight 1.2)

$context.DrawRoundedRectangle($lightFill, $null, [System.Windows.Rect]::new(48, 714, 1104, 150), 34, 34)
[void](Draw-TextBlock -Context $context -Text 'Absolute Automation.' -X 88 -Y 756 -Width 340 -Size 28 -Brush $lightText -Weight 'Bold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'A Divi-native global theme export with sharp contrast, bold typography, and a composed enterprise layout.' -X 88 -Y 800 -Width 340 -Size 15 -Brush $mutedDark -Weight 'Normal' -LineHeight 1.25)

$workflowCardY = 744
$workflowCardWidth = 198
$workflowCardHeight = 92
$workflowCardX = 540
for ($i = 0; $i -lt 3; $i++) {
	$x = $workflowCardX + ($i * 212)
	$context.DrawRoundedRectangle((New-SolidBrush -Hex 'FFFFFF' -Alpha 255), $lightLinePen, [System.Windows.Rect]::new($x, $workflowCardY, $workflowCardWidth, $workflowCardHeight), 24, 24)
}

[void](Draw-TextBlock -Context $context -Text 'Rapid execution' -X 566 -Y 770 -Width 150 -Size 18 -Brush $lightText -Weight 'SemiBold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'Move from intake to action without drag.' -X 566 -Y 800 -Width 150 -Size 12 -Brush $mutedDark -Weight 'Normal' -LineHeight 1.2)

[void](Draw-TextBlock -Context $context -Text 'Lean operations' -X 778 -Y 770 -Width 150 -Size 18 -Brush $lightText -Weight 'SemiBold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'Replace repetitive work with stable flows.' -X 778 -Y 800 -Width 150 -Size 12 -Brush $mutedDark -Weight 'Normal' -LineHeight 1.2)

[void](Draw-TextBlock -Context $context -Text 'Error eradication' -X 990 -Y 770 -Width 140 -Size 18 -Brush $lightText -Weight 'SemiBold' -LineHeight 1.0)
[void](Draw-TextBlock -Context $context -Text 'Reduce manual failure points across delivery.' -X 990 -Y 800 -Width 128 -Size 12 -Brush $mutedDark -Weight 'Normal' -LineHeight 1.2)

$context.Close()

$renderTarget = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
	$width,
	$height,
	96,
	96,
	[System.Windows.Media.PixelFormats]::Pbgra32
)
$renderTarget.Render($visual)

$encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($renderTarget))

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutputPath)
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

$stream = [System.IO.File]::Open($resolvedOutputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
try {
	$encoder.Save($stream)
}
finally {
	$stream.Dispose()
}

Write-Host "Generated $resolvedOutputPath"
