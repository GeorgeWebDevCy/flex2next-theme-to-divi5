Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repoRoot 'exports'
$homepageOutputPath = Join-Path $outputDir 'flex2next-divi5-homepage.json'
$themeBuilderOutputPath = Join-Path $outputDir 'flex2next-divi5-theme-builder.json'
$childThemeStylePath = Join-Path $repoRoot 'flex2next-divi-child/style.css'

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

function New-ResponsiveValue {
	param(
		[Parameter(Mandatory = $true)]
		$Value
	)

	return [ordered]@{
		desktop = [ordered]@{
			value = $Value
		}
	}
}

function Copy-Dictionary {
	param(
		[Parameter(Mandatory = $true)]
		[System.Collections.IDictionary]$Source
	)

	$copy = [ordered]@{}

	foreach ($key in $Source.Keys) {
		$value = $Source[$key]

		if ($value -is [System.Collections.IDictionary]) {
			$copy[$key] = Copy-Dictionary -Source $value
			continue
		}

		if ($value -is [System.Collections.IList] -and -not ($value -is [string])) {
			$listCopy = @()

			foreach ($item in $value) {
				if ($item -is [System.Collections.IDictionary]) {
					$listCopy += , (Copy-Dictionary -Source $item)
				} else {
					$listCopy += , $item
				}
			}

			$copy[$key] = $listCopy
			continue
		}

		$copy[$key] = $value
	}

	return $copy
}

function Merge-Dictionary {
	param(
		[Parameter(Mandatory = $true)]
		[System.Collections.IDictionary]$Base,
		[Parameter(Mandatory = $true)]
		[System.Collections.IDictionary]$Extra
	)

	$merged = Copy-Dictionary -Source $Base

	foreach ($key in $Extra.Keys) {
		$incoming = $Extra[$key]

		if (
			$merged.Contains($key) -and
			$merged[$key] -is [System.Collections.IDictionary] -and
			$incoming -is [System.Collections.IDictionary]
		) {
			$merged[$key] = Merge-Dictionary -Base $merged[$key] -Extra $incoming
			continue
		}

		if ($incoming -is [System.Collections.IDictionary]) {
			$merged[$key] = Copy-Dictionary -Source $incoming
			continue
		}

		$merged[$key] = $incoming
	}

	return $merged
}

function New-ModuleObject {
	param(
		[string]$AdminLabel = '',
		[string]$Class = '',
		[string]$Id = '',
		[hashtable]$Extra = @{}
	)

	$module = [ordered]@{}

	if ($AdminLabel) {
		$module['meta'] = [ordered]@{
			adminLabel = New-ResponsiveValue -Value $AdminLabel
		}
	}

	if ($Class -or $Id) {
		$htmlAttributes = [ordered]@{}

		if ($Id) {
			$htmlAttributes['id'] = $Id
		}

		if ($Class) {
			$htmlAttributes['class'] = $Class
		}

		$module['advanced'] = [ordered]@{
			htmlAttributes = New-ResponsiveValue -Value $htmlAttributes
		}
	}

	if ($Extra.Count -gt 0) {
		$module = Merge-Dictionary -Base $module -Extra $Extra
	}

	return $module
}

function New-Block {
	param(
		[Parameter(Mandatory = $true)]
		[string]$BlockName,
		[hashtable]$Attrs = @{},
		[object[]]$InnerBlocks = @()
	)

	return [ordered]@{
		blockName   = $BlockName
		attrs       = $Attrs
		innerBlocks = $InnerBlocks
	}
}

function Serialize-Block {
	param(
		[Parameter(Mandatory = $true)]
		[hashtable]$Block
	)

	$attrsJson = ''

	if ($Block['attrs'].Count -gt 0) {
		$attrsJson = ' ' + ($Block['attrs'] | ConvertTo-Json -Compress -Depth 100)
	}

	$blockName = $Block['blockName']
	$innerBlocks = @($Block['innerBlocks'])

	if ($innerBlocks.Count -eq 0) {
		return "<!-- wp:$blockName$attrsJson /-->"
	}

	$innerContent = ($innerBlocks | ForEach-Object { Serialize-Block -Block $_ }) -join "`n"

	return "<!-- wp:$blockName$attrsJson -->`n$innerContent`n<!-- /wp:$blockName -->"
}

function New-TextBlock {
	param(
		[Parameter(Mandatory = $true)]
		[string]$AdminLabel,
		[Parameter(Mandatory = $true)]
		[string]$Html,
		[string]$Class = '',
		[string]$Id = ''
	)

	$attrs = [ordered]@{
		module  = New-ModuleObject -AdminLabel $AdminLabel -Class $Class -Id $Id
		content = [ordered]@{
			innerContent = New-ResponsiveValue -Value $Html
		}
	}

	return New-Block -BlockName 'divi/text' -Attrs $attrs
}

function New-ColumnBlock {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Type,
		[Parameter(Mandatory = $true)]
		[string]$AdminLabel,
		[object[]]$InnerBlocks = @(),
		[string]$Class = '',
		[string]$Id = ''
	)

	$extra = [ordered]@{
		advanced = [ordered]@{
			type = New-ResponsiveValue -Value $Type
		}
	}

	$attrs = [ordered]@{
		module = New-ModuleObject -AdminLabel $AdminLabel -Class $Class -Id $Id -Extra $extra
	}

	return New-Block -BlockName 'divi/column' -Attrs $attrs -InnerBlocks $InnerBlocks
}

function New-RowBlock {
	param(
		[Parameter(Mandatory = $true)]
		[string]$AdminLabel,
		[object[]]$InnerBlocks = @(),
		[string]$Class = '',
		[string]$Id = ''
	)

	$attrs = [ordered]@{
		module = New-ModuleObject -AdminLabel $AdminLabel -Class $Class -Id $Id
	}

	return New-Block -BlockName 'divi/row' -Attrs $attrs -InnerBlocks $InnerBlocks
}

function New-SectionBlock {
	param(
		[Parameter(Mandatory = $true)]
		[string]$AdminLabel,
		[object[]]$InnerBlocks = @(),
		[string]$Class = '',
		[string]$Id = ''
	)

	$attrs = [ordered]@{
		module = New-ModuleObject -AdminLabel $AdminLabel -Class $Class -Id $Id
	}

	return New-Block -BlockName 'divi/section' -Attrs $attrs -InnerBlocks $InnerBlocks
}

function Get-PortableStylesheetContent {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	$css = Get-Content -Path $Path -Raw
	$css = [regex]::Replace($css, '(?s)^/\*.*?\*/\s*', '')
	$css = [regex]::Replace($css, '(?s)@font-face\s*\{.*?\}\s*', '')

	return $css.Trim()
}

function New-ThemeBuilderLayoutExport {
	param(
		[Parameter(Mandatory = $true)]
		[int]$LayoutId,
		[Parameter(Mandatory = $true)]
		[string]$LayoutContent,
		[Parameter(Mandatory = $true)]
		[string]$PostType,
		[Parameter(Mandatory = $true)]
		[bool]$IsGlobal,
		[object[]]$PostMeta = @()
	)

	return [ordered]@{
		context       = 'et_builder'
		data          = [ordered]@{
			"$LayoutId" = $LayoutContent
		}
		images        = @()
		thumbnails    = @()
		post_type     = $PostType
		theme_builder = [ordered]@{
			is_global = $IsGlobal
		}
		post_meta     = $PostMeta
	}
}

function Write-JsonFile {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[Parameter(Mandatory = $true)]
		$Data
	)

	$json = $Data | ConvertTo-Json -Depth 100
	$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
	[System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
	Get-Content -Path $Path -Raw | ConvertFrom-Json | Out-Null
}

$globalColors = @(
	@('gcid-flex2-background', @{ color = '#000000'; status = 'active'; label = 'Flex2 Background' }),
	@('gcid-flex2-foreground', @{ color = '#fafafa'; status = 'active'; label = 'Flex2 Foreground' }),
	@('gcid-flex2-surface', @{ color = '#fafafa0d'; status = 'active'; label = 'Flex2 Surface' }),
	@('gcid-flex2-border', @{ color = '#fafafa1a'; status = 'active'; label = 'Flex2 Border' }),
	@('gcid-flex2-text-secondary', @{ color = '#fafafa99'; status = 'active'; label = 'Flex2 Text Secondary' }),
	@('gcid-flex2-inverted-background', @{ color = '#f5f5f5'; status = 'active'; label = 'Flex2 Inverted Background' }),
	@('gcid-flex2-inverted-foreground', @{ color = '#000000'; status = 'active'; label = 'Flex2 Inverted Foreground' })
)

$globalVariables = @(
	@{ id = 'gvid-flex2-site-width'; label = 'Site Width'; value = '80rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-content-width'; label = 'Content Width'; value = '48rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-radius-card'; label = 'Card Radius'; value = '1.5rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-radius-pill'; label = 'Pill Radius'; value = '999rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-body'; label = 'Body Font'; value = 'Flex2 Geist'; status = 'active'; type = 'fonts' },
	@{ id = 'gvid-flex2-font-mono'; label = 'Mono Font'; value = 'Flex2 Geist Mono'; status = 'active'; type = 'fonts' }
)

$portableSharedCss = Get-PortableStylesheetContent -Path $childThemeStylePath
$sharedCssPostMeta = @(
	[ordered]@{
		key   = '_et_pb_custom_css'
		value = $portableSharedCss
	}
)

$siteBaseUrl = 'https://dominicb83.sg-host.com/'
$philosophyUrl = "${siteBaseUrl}#philosophy"
$workflowsUrl = "${siteBaseUrl}#workflows"
$benefitsUrl = "${siteBaseUrl}#benefits"
$contactUrl = "${siteBaseUrl}#contact"

$headerBrandHtml = @"
<a href="$siteBaseUrl" class="fx2-brand-link" aria-label="Flex2 Ai Home">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"></path>
  </svg>
  <span>Flex2 Ai</span>
</a>
"@

$headerNavHtml = "<div class=`"fx2-header-nav-inner`"><div class=`"fx2-header-nav-desktop`"><nav class=`"fx2-header-links`" aria-label=`"Primary`"><a href=`"$philosophyUrl`">Philosophy</a><a href=`"$workflowsUrl`">Workflows</a><a href=`"$benefitsUrl`">Benefits</a></nav><a href=`"$contactUrl`" class=`"fx2-button fx2-button-small`">Initiate Consultation</a></div><details class=`"fx2-mobile-nav`"><summary class=`"fx2-mobile-nav-toggle`" aria-label=`"Open navigation`"><span class=`"fx2-mobile-nav-icon`" aria-hidden=`"true`"><span></span><span></span><span></span></span></summary><div class=`"fx2-mobile-nav-panel`"><nav class=`"fx2-mobile-nav-links`" aria-label=`"Mobile Primary`"><a href=`"$philosophyUrl`">Philosophy</a><a href=`"$workflowsUrl`">Workflows</a><a href=`"$benefitsUrl`">Benefits</a></nav><a href=`"$contactUrl`" class=`"fx2-button fx2-button-small fx2-mobile-nav-cta`">Initiate Consultation</a></div></details></div>"

$heroTitleHtml = @'
<h1>Invisible<br /><span>Intelligence.</span></h1>
'@

$heroCopyHtml = @'
<p>We engineer bespoke automation workflows that silently eradicate tedious admin, drastically reduce overhead, and scale your business globally.</p>
'@

$heroActionsHtml = @"
<div class="fx2-hero-actions-wrap">
  <a href="$contactUrl" class="fx2-button fx2-button-large">Automate Your Future <span aria-hidden="true">&rarr;</span></a>
  <p class="fx2-hero-coverage">Servicing UK, US &amp; EU Markets</p>
</div>
"@

$locationsIntroHtml = @'
<p>Optimized for enterprise scale across global jurisdictions</p>
'@

$locationsListHtml = @'
<ul class="fx2-location-list" aria-label="Office locations">
  <li>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="10"></circle>
      <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
      <path d="M2 12h20"></path>
    </svg>
    <span>London, UK</span>
  </li>
  <li>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="10"></circle>
      <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
      <path d="M2 12h20"></path>
    </svg>
    <span>New York, US</span>
  </li>
  <li>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="10"></circle>
      <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
      <path d="M2 12h20"></path>
    </svg>
    <span>Berlin, EU</span>
  </li>
</ul>
'@

$philosophyTitleHtml = @'
<h2>We hide the complex machinery. You simply reap the incomprehensible benefits.</h2>
'@

$philosophyCopyHtml = @'
<h3>The Flex2 Ai Paradigm</h3>
<p>As an arm of Flex2 Digital Technologies Group, we believe AI should not be a scientific lecture. You do not need to understand neural networks or token limits. You just need results.</p>
<p>We are the architects of the unseen. We diagnose your bottlenecks, build the sophisticated workflows in the background, and deliver a streamlined, minimalist solution that simply works.</p>
'@

$philosophyGraphicHtml = @'
<div class="fx2-philosophy-graphic-shell" aria-hidden="true">
  <div class="fx2-dot-pattern"></div>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round">
    <rect x="16" y="16" width="6" height="6" rx="1"></rect>
    <rect x="2" y="16" width="6" height="6" rx="1"></rect>
    <rect x="9" y="2" width="6" height="6" rx="1"></rect>
    <path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"></path>
    <path d="M12 12V8"></path>
  </svg>
</div>
'@

$workflowsIntroHtml = @'
<h2>Absolute Automation.</h2>
<p>Our custom-built workflows target the heavy, tedious admin tasks that drain your resources and bloat your overhead.</p>
'@

$workflowCardOneHtml = @'
<div class="fx2-workflow-card-shell">
  <div class="fx2-workflow-icon" aria-hidden="true">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
      <path d="M13 2 3 14h7l-1 8 10-12h-7l1-8z"></path>
    </svg>
  </div>
  <h3>Rapid Execution</h3>
  <p>Processes that took human teams hours or days are reduced to milliseconds. Perfect execution, zero fatigue.</p>
</div>
'@

$workflowCardTwoHtml = @'
<div class="fx2-workflow-card-shell">
  <div class="fx2-workflow-icon" aria-hidden="true">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
      <path d="M4 6h16"></path>
      <path d="M4 12h16"></path>
      <path d="M4 18h10"></path>
      <path d="M18 15v6"></path>
      <path d="M15 18h6"></path>
    </svg>
  </div>
  <h3>Lean Operations</h3>
  <p>Slash operational overhead. Scale your output exponentially without the need to proportionally scale your headcount.</p>
</div>
'@

$workflowCardThreeHtml = @'
<div class="fx2-workflow-card-shell">
  <div class="fx2-workflow-icon" aria-hidden="true">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
      <path d="m9 12 2 2 4-4"></path>
    </svg>
  </div>
  <h3>Error Eradication</h3>
  <p>Remove human error from critical data entry and administrative workflows, ensuring uncompromised data integrity.</p>
</div>
'@

$benefitsIntroHtml = @'
<p class="fx2-eyebrow">The Bottom Line</p>
<h2>We do not sell software. We sell <span>time and money.</span></h2>
'@

$statOneHtml = @'
<div class="fx2-benefit-stat">
  <span class="fx2-benefit-value">90%</span>
  <span class="fx2-benefit-label">Time Saved</span>
</div>
'@

$statTwoHtml = @'
<div class="fx2-benefit-stat">
  <span class="fx2-benefit-value">24/7</span>
  <span class="fx2-benefit-label">Continuous Output</span>
</div>
'@

$statThreeHtml = @'
<div class="fx2-benefit-stat">
  <span class="fx2-benefit-value">60%</span>
  <span class="fx2-benefit-label">Overhead Reduction</span>
</div>
'@

$statFourHtml = @'
<div class="fx2-benefit-stat">
  <span class="fx2-benefit-value">&infin;</span>
  <span class="fx2-benefit-label">Scalability</span>
</div>
'@

$contactCopyHtml = @'
<h2>Initiate Evolution.</h2>
<p>Secure your consultation. Discover exactly how much time and capital Flex2 Ai can reclaim for your enterprise.</p>
'@

$contactFormHtml = @'
<div class="fx2-contact-form-shell">[fluentform id="1"]</div>
'@

$footerBrandHtml = @'
<div class="fx2-footer-brand-shell">
  <span class="fx2-footer-brand-mark">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"></path>
    </svg>
    <span>Flex2 Ai</span>
  </span>
  <p>Invisible intelligence for enterprise operations.</p>
</div>
'@

$footerLegalHtml = @'
<p>&copy; Flex2 Ai. All rights reserved.</p>
'@

$footerLinksHtml = @'
<nav class="fx2-footer-links-shell" aria-label="Footer">
  <a href="/privacy-policy/">Privacy Policy</a>
  <a href="/terms-of-service/">Terms of Service</a>
</nav>
'@

$homepageLayoutTree = New-Block -BlockName 'divi/placeholder' -InnerBlocks @(
	(New-SectionBlock -AdminLabel 'Hero Section' -Class 'fx2-home-hero' -Id 'top' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Hero Row' -Class 'fx2-container fx2-hero-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Hero Column' -Class 'fx2-hero-column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Hero Title' -Class 'fx2-home-hero-title' -Html $heroTitleHtml),
				(New-TextBlock -AdminLabel 'Hero Copy' -Class 'fx2-home-hero-copy' -Html $heroCopyHtml),
				(New-TextBlock -AdminLabel 'Hero Actions' -Class 'fx2-home-hero-actions' -Html $heroActionsHtml)
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Locations Section' -Class 'fx2-home-locations' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Locations Row' -Class 'fx2-container fx2-locations-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Locations Intro Column' -Class 'fx2-locations-copy-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Locations Intro' -Class 'fx2-home-locations-copy' -Html $locationsIntroHtml)
			)),
			(New-ColumnBlock -Type '2_3' -AdminLabel 'Locations List Column' -Class 'fx2-locations-list-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Locations List' -Class 'fx2-home-locations-list' -Html $locationsListHtml)
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Philosophy Section' -Class 'fx2-home-philosophy' -Id 'philosophy' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Philosophy Title Row' -Class 'fx2-container fx2-philosophy-title-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Philosophy Title Column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Philosophy Title' -Class 'fx2-home-philosophy-title' -Html $philosophyTitleHtml)
			))
		)),
		(New-RowBlock -AdminLabel 'Philosophy Content Row' -Class 'fx2-container fx2-philosophy-content-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Philosophy Copy Column' -Class 'fx2-philosophy-copy-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Philosophy Copy' -Class 'fx2-home-philosophy-copy' -Html $philosophyCopyHtml)
			)),
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Philosophy Graphic Column' -Class 'fx2-philosophy-graphic-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Philosophy Graphic' -Class 'fx2-home-philosophy-graphic' -Html $philosophyGraphicHtml)
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Workflows Section' -Class 'fx2-home-workflows' -Id 'workflows' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Workflows Intro Row' -Class 'fx2-container fx2-workflows-intro-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Workflows Intro Column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflows Intro' -Class 'fx2-home-workflows-intro' -Html $workflowsIntroHtml)
			))
		)),
		(New-RowBlock -AdminLabel 'Workflows Grid Row' -Class 'fx2-container fx2-workflows-grid-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Workflow One Column' -Class 'fx2-workflow-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflow One' -Class 'fx2-home-workflow-card' -Html $workflowCardOneHtml)
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Workflow Two Column' -Class 'fx2-workflow-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflow Two' -Class 'fx2-home-workflow-card' -Html $workflowCardTwoHtml)
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Workflow Three Column' -Class 'fx2-workflow-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflow Three' -Class 'fx2-home-workflow-card' -Html $workflowCardThreeHtml)
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Benefits Section' -Class 'fx2-home-benefits' -Id 'benefits' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Benefits Intro Row' -Class 'fx2-container fx2-benefits-intro-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Benefits Intro Column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Benefits Intro' -Class 'fx2-home-benefits-intro' -Html $benefitsIntroHtml)
			))
		)),
		(New-RowBlock -AdminLabel 'Benefits Stats Row' -Class 'fx2-container fx2-benefits-stats-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat One Column' -Class 'fx2-benefit-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat One' -Class 'fx2-home-benefit-stat' -Html $statOneHtml)
			)),
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat Two Column' -Class 'fx2-benefit-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat Two' -Class 'fx2-home-benefit-stat' -Html $statTwoHtml)
			)),
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat Three Column' -Class 'fx2-benefit-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat Three' -Class 'fx2-home-benefit-stat' -Html $statThreeHtml)
			)),
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat Four Column' -Class 'fx2-benefit-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat Four' -Class 'fx2-home-benefit-stat' -Html $statFourHtml)
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Contact Section' -Class 'fx2-home-contact' -Id 'contact' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Contact Row' -Class 'fx2-container fx2-contact-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Contact Column' -Class 'fx2-contact-column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Contact Copy' -Class 'fx2-home-contact-copy' -Html $contactCopyHtml),
				(New-TextBlock -AdminLabel 'Contact Form' -Class 'fx2-home-contact-form' -Html $contactFormHtml)
			))
		))
	))
)

$headerLayoutTree = New-Block -BlockName 'divi/placeholder' -InnerBlocks @(
	(New-SectionBlock -AdminLabel 'Global Header Section' -Class 'fx2-global-header' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Global Header Row' -Class 'fx2-container fx2-header-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Header Brand Column' -Class 'fx2-header-brand-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Header Brand' -Class 'fx2-header-brand' -Html $headerBrandHtml)
			)),
			(New-ColumnBlock -Type '3_4' -AdminLabel 'Header Navigation Column' -Class 'fx2-header-nav-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Header Navigation' -Class 'fx2-header-nav' -Html $headerNavHtml)
			))
		))
	))
)

$footerLayoutTree = New-Block -BlockName 'divi/placeholder' -InnerBlocks @(
	(New-SectionBlock -AdminLabel 'Global Footer Section' -Class 'fx2-global-footer' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Global Footer Row' -Class 'fx2-container fx2-footer-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Footer Brand Column' -Class 'fx2-footer-brand-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Footer Brand' -Class 'fx2-footer-brand' -Html $footerBrandHtml)
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Footer Legal Column' -Class 'fx2-footer-legal-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Footer Legal' -Class 'fx2-footer-legal' -Html $footerLegalHtml)
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Footer Links Column' -Class 'fx2-footer-links-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Footer Links' -Class 'fx2-footer-links' -Html $footerLinksHtml)
			))
		))
	))
)

$homepageLayoutContent = Serialize-Block -Block $homepageLayoutTree
$headerLayoutContent = Serialize-Block -Block $headerLayoutTree
$footerLayoutContent = Serialize-Block -Block $footerLayoutTree

$homepageExport = [ordered]@{
	context            = 'et_builder'
	data               = [ordered]@{
		'flex2next-homepage' = $homepageLayoutContent
	}
	presets            = @()
	global_colors      = $globalColors
	global_variables   = $globalVariables
	page_settings_meta = [ordered]@{
		_et_pb_custom_css = $portableSharedCss
	}
	canvases           = [ordered]@{
		local  = @()
		global = @()
	}
	images             = @()
	thumbnails         = @()
}

$headerLayoutId = 910001
$footerLayoutId = 910002

$themeBuilderExport = [ordered]@{
	context              = 'et_theme_builder'
	templates            = @(
		[ordered]@{
			title               = 'Default Website Template'
			autogenerated_title = $false
			default             = $true
			enabled             = $true
			use_on              = @()
			exclude_from        = @()
			layouts             = [ordered]@{
				header = [ordered]@{
					id      = $headerLayoutId
					enabled = $true
				}
				body   = [ordered]@{
					id      = 0
					enabled = $true
				}
				footer = [ordered]@{
					id      = $footerLayoutId
					enabled = $true
				}
			}
		}
	)
	layouts             = [ordered]@{
		"$headerLayoutId" = New-ThemeBuilderLayoutExport -LayoutId $headerLayoutId -LayoutContent $headerLayoutContent -PostType 'et_header_layout' -IsGlobal $true -PostMeta $sharedCssPostMeta
		"$footerLayoutId" = New-ThemeBuilderLayoutExport -LayoutId $footerLayoutId -LayoutContent $footerLayoutContent -PostType 'et_footer_layout' -IsGlobal $true -PostMeta $sharedCssPostMeta
	}
	has_default_template = $true
	has_global_layouts   = $true
	presets              = @()
	global_colors        = $globalColors
	global_variables     = $globalVariables
}

Write-JsonFile -Path $homepageOutputPath -Data $homepageExport
Write-JsonFile -Path $themeBuilderOutputPath -Data $themeBuilderExport

Write-Output "Generated $homepageOutputPath"
Write-Output "Generated $themeBuilderOutputPath"
