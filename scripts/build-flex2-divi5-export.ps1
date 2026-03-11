Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repoRoot 'exports'
$outputPath = Join-Path $outputDir 'flex2next-divi5-homepage.json'

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

function New-ButtonBlock {
	param(
		[Parameter(Mandatory = $true)]
		[string]$AdminLabel,
		[Parameter(Mandatory = $true)]
		[string]$Text,
		[Parameter(Mandatory = $true)]
		[string]$LinkUrl,
		[string]$Class = '',
		[string]$Id = '',
		[bool]$OpenInNewTab = $false
	)

	$attrs = [ordered]@{
		module = New-ModuleObject -AdminLabel $AdminLabel -Class $Class -Id $Id
		button = [ordered]@{
			innerContent = New-ResponsiveValue -Value ([ordered]@{
				text       = $Text
				linkUrl    = $LinkUrl
				linkTarget = if ($OpenInNewTab) { 'on' } else { 'off' }
			})
		}
	}

	return New-Block -BlockName 'divi/button' -Attrs $attrs
}

function New-CodeBlock {
	param(
		[Parameter(Mandatory = $true)]
		[string]$AdminLabel,
		[Parameter(Mandatory = $true)]
		[string]$Code,
		[string]$Class = '',
		[string]$Id = ''
	)

	$attrs = [ordered]@{
		module  = New-ModuleObject -AdminLabel $AdminLabel -Class $Class -Id $Id
		content = [ordered]@{
			innerContent = New-ResponsiveValue -Value $Code
		}
	}

	return New-Block -BlockName 'divi/code' -Attrs $attrs
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

$layoutTree = New-Block -BlockName 'divi/placeholder' -InnerBlocks @(
	(New-SectionBlock -AdminLabel 'Header Section' -Class 'fx2-header-section' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Header Row' -Class 'fx2-row fx2-header-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Brand Column' -Class 'fx2-header-brand-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Brand' -Class 'fx2-brand' -Html '<a href="#top">Flex2 Ai</a>')
			)),
			(New-ColumnBlock -Type '3_4' -AdminLabel 'Navigation Column' -Class 'fx2-header-nav-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Navigation' -Class 'fx2-nav' -Html '<div class="fx2-nav-links"><a href="#philosophy">Philosophy</a><a href="#workflows">Workflows</a><a href="#benefits">Benefits</a></div>'),
				(New-ButtonBlock -AdminLabel 'Header CTA' -Class 'fx2-primary-button fx2-header-cta' -Text 'Initiate Consultation' -LinkUrl '#contact')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Hero Section' -Class 'fx2-hero-section' -Id 'top' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Hero Row' -Class 'fx2-row fx2-hero-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Hero Column' -Class 'fx2-hero-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Hero Badge' -Class 'fx2-hero-badge' -Html '<p>The New Standard in B2B AI</p>'),
				(New-TextBlock -AdminLabel 'Hero Title' -Class 'fx2-hero-title' -Html '<h1><span>Invisible</span><span>Intelligence.</span></h1>'),
				(New-TextBlock -AdminLabel 'Hero Copy' -Class 'fx2-hero-copy' -Html '<p>We engineer bespoke automation workflows that silently eradicate tedious admin, drastically reduce overhead, and scale your business globally.</p>'),
				(New-ButtonBlock -AdminLabel 'Hero CTA' -Class 'fx2-primary-button fx2-hero-cta' -Text 'Automate Your Future' -LinkUrl '#contact'),
				(New-TextBlock -AdminLabel 'Hero Markets' -Class 'fx2-service-note' -Html '<p>Servicing UK, US &amp; EU Markets</p>')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Locations Section' -Class 'fx2-locations-section' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Locations Intro Row' -Class 'fx2-row fx2-locations-intro-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Locations Intro Column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Locations Intro' -Class 'fx2-section-intro fx2-locations-intro' -Html '<p class="fx2-kicker">Global Coverage</p><h2>Optimized for enterprise scale across global jurisdictions</h2>')
			))
		)),
		(New-RowBlock -AdminLabel 'Locations Grid Row' -Class 'fx2-row fx2-locations-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Location One Column' -Class 'fx2-location-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Location One' -Class 'fx2-location-card' -Html '<p>London, UK</p>')
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Location Two Column' -Class 'fx2-location-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Location Two' -Class 'fx2-location-card' -Html '<p>New York, US</p>')
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Location Three Column' -Class 'fx2-location-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Location Three' -Class 'fx2-location-card' -Html '<p>Berlin, EU</p>')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Philosophy Section' -Class 'fx2-philosophy-section' -Id 'philosophy' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Philosophy Row' -Class 'fx2-row fx2-philosophy-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Philosophy Intro Column' -Class 'fx2-philosophy-intro-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Philosophy Intro' -Class 'fx2-section-intro fx2-philosophy-intro' -Html '<p class="fx2-kicker">The Flex2 Ai Paradigm</p><h2>We hide the complex machinery. You simply reap the incomprehensible benefits.</h2>')
			)),
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Philosophy Copy Column' -Class 'fx2-philosophy-copy-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Philosophy Copy' -Class 'fx2-philosophy-copy' -Html '<p>As an arm of Flex2 Digital Technologies Group, we believe AI shouldn&#8217;t be a scientific lecture. You don&#8217;t need to understand neural networks or token limits. You just need results.</p><p>We are the architects of the unseen. We diagnose your bottlenecks, build the sophisticated workflows in the background, and deliver a streamlined, minimalist solution that simply works.</p>')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Workflows Section' -Class 'fx2-workflows-section' -Id 'workflows' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Workflows Intro Row' -Class 'fx2-row fx2-workflows-intro-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Workflows Intro Column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflows Intro' -Class 'fx2-section-intro fx2-workflows-intro' -Html '<p class="fx2-kicker">Absolute Automation.</p><p>Our custom-built workflows target the heavy, tedious admin tasks that drain your resources and bloat your overhead.</p>')
			))
		)),
		(New-RowBlock -AdminLabel 'Workflow Cards Row' -Class 'fx2-row fx2-workflow-cards-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Workflow Card One Column' -Class 'fx2-workflow-card-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflow Card One' -Class 'fx2-workflow-card' -Html '<p class="fx2-card-index">01</p><h3>Rapid Execution</h3><p>Processes that took human teams hours or days are reduced to milliseconds. Perfect execution, zero fatigue.</p>')
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Workflow Card Two Column' -Class 'fx2-workflow-card-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflow Card Two' -Class 'fx2-workflow-card' -Html '<p class="fx2-card-index">02</p><h3>Lean Operations</h3><p>Slash operational overhead. Scale your output exponentially without the need to proportionally scale your headcount.</p>')
			)),
			(New-ColumnBlock -Type '1_3' -AdminLabel 'Workflow Card Three Column' -Class 'fx2-workflow-card-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Workflow Card Three' -Class 'fx2-workflow-card' -Html '<p class="fx2-card-index">03</p><h3>Error Eradication</h3><p>Remove human error from critical data entry and administrative workflows. Ensuring uncompromised data integrity.</p>')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Benefits Section' -Class 'fx2-benefits-section' -Id 'benefits' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Benefits Intro Row' -Class 'fx2-row fx2-benefits-intro-row' -InnerBlocks @(
			(New-ColumnBlock -Type '4_4' -AdminLabel 'Benefits Intro Column' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Benefits Intro' -Class 'fx2-section-intro fx2-benefits-intro' -Html '<p class="fx2-kicker">The Bottom Line</p><h2>We don&#8217;t sell software. We sell time and money.</h2>')
			))
		)),
		(New-RowBlock -AdminLabel 'Stats Row' -Class 'fx2-row fx2-stats-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat One Column' -Class 'fx2-stat-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat One' -Class 'fx2-stat-card' -Html '<p class="fx2-stat-value">90%</p><p class="fx2-stat-label">Time Saved</p>')
			)),
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat Two Column' -Class 'fx2-stat-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat Two' -Class 'fx2-stat-card' -Html '<p class="fx2-stat-value">24/7</p><p class="fx2-stat-label">Continuous Output</p>')
			)),
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat Three Column' -Class 'fx2-stat-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat Three' -Class 'fx2-stat-card' -Html '<p class="fx2-stat-value">60%</p><p class="fx2-stat-label">Overhead Reduction</p>')
			)),
			(New-ColumnBlock -Type '1_4' -AdminLabel 'Stat Four Column' -Class 'fx2-stat-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Stat Four' -Class 'fx2-stat-card' -Html '<p class="fx2-stat-value">&infin;</p><p class="fx2-stat-label">Scalability</p>')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Contact Section' -Class 'fx2-contact-section' -Id 'contact' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Contact Row' -Class 'fx2-row fx2-contact-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Contact Copy Column' -Class 'fx2-contact-copy-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Contact Copy' -Class 'fx2-contact-copy' -Html '<h2>Initiate Evolution.</h2><p>Secure your consultation. Discover exactly how much time and capital Flex2 Ai can reclaim for your enterprise.</p>')
			)),
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Contact Form Column' -Class 'fx2-contact-form-col' -InnerBlocks @(
				(New-CodeBlock -AdminLabel 'Contact Form Shortcode' -Class 'fx2-contact-form-wrap' -Code '[fluentform id="1"]')
			))
		))
	)),
	(New-SectionBlock -AdminLabel 'Footer Section' -Class 'fx2-footer-section' -InnerBlocks @(
		(New-RowBlock -AdminLabel 'Footer Row' -Class 'fx2-row fx2-footer-row' -InnerBlocks @(
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Footer Brand Column' -Class 'fx2-footer-brand-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Footer Brand' -Class 'fx2-footer-brand' -Html '<p class="fx2-footer-mark">Flex2 Ai</p><p>Invisible intelligence for enterprise operations.</p>')
			)),
			(New-ColumnBlock -Type '1_2' -AdminLabel 'Footer Links Column' -Class 'fx2-footer-links-col' -InnerBlocks @(
				(New-TextBlock -AdminLabel 'Footer Links' -Class 'fx2-footer-links' -Html '<div class="fx2-footer-meta"><span>&copy; Flex2 Ai. All rights reserved.</span><a href="/privacy-policy/">Privacy Policy</a><a href="/terms-of-service/">Terms of Service</a></div>')
			))
		))
	))
)

$layoutContent = Serialize-Block -Block $layoutTree

$globalColors = @(
	@('gcid-flex2-background', @{ color = '#000000'; status = 'active'; label = 'Flex2 Background' }),
	@('gcid-flex2-foreground', @{ color = '#fafafa'; status = 'active'; label = 'Flex2 Foreground' }),
	@('gcid-flex2-surface', @{ color = '#fafafa0d'; status = 'active'; label = 'Flex2 Surface' }),
	@('gcid-flex2-surface-hover', @{ color = '#fafafa14'; status = 'active'; label = 'Flex2 Surface Hover' }),
	@('gcid-flex2-border', @{ color = '#fafafa1a'; status = 'active'; label = 'Flex2 Border' }),
	@('gcid-flex2-text-secondary', @{ color = '#fafafa99'; status = 'active'; label = 'Flex2 Text Secondary' }),
	@('gcid-flex2-text-tertiary', @{ color = '#fafafa66'; status = 'active'; label = 'Flex2 Text Tertiary' }),
	@('gcid-flex2-text-subtle', @{ color = '#fafafa80'; status = 'active'; label = 'Flex2 Text Subtle' })
)

$globalVariables = @(
	@{ id = 'gvid-flex2-space-site-gutter'; label = 'Site Gutter'; value = 'clamp(1.25rem, 2vw, 2rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-space-header-y'; label = 'Header Padding'; value = '1rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-space-section-y'; label = 'Section Spacing'; value = 'clamp(4rem, 9vw, 8rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-space-section-y-tight'; label = 'Tight Section Spacing'; value = 'clamp(3rem, 7vw, 5rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-space-card-padding'; label = 'Card Padding'; value = 'clamp(1.5rem, 2.4vw, 2.25rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-space-block-gap'; label = 'Block Gap'; value = 'clamp(1rem, 2vw, 1.5rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-space-grid-gap'; label = 'Grid Gap'; value = 'clamp(1rem, 2.5vw, 1.75rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-max-width'; label = 'Content Width'; value = '78rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-copy-max-width'; label = 'Copy Width'; value = '44rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-radius-card'; label = 'Card Radius'; value = '1.5rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-radius-pill'; label = 'Pill Radius'; value = '999rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-border-width'; label = 'Border Width'; value = '0.0625rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-body'; label = 'Body Size'; value = 'clamp(1rem, 0.25vw + 0.95rem, 1.125rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-small'; label = 'Small Size'; value = '0.875rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-label'; label = 'Label Size'; value = '0.8125rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-nav'; label = 'Nav Size'; value = '0.95rem'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-hero'; label = 'Hero Size'; value = 'clamp(3.5rem, 10vw, 8rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-display'; label = 'Display Size'; value = 'clamp(2.35rem, 5vw, 4.25rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-size-stat'; label = 'Stat Size'; value = 'clamp(2.5rem, 6vw, 4.75rem)'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-line-height-tight'; label = 'Tight Line Height'; value = '0.92'; status = 'active'; type = 'numbers' },
	@{ id = 'gvid-flex2-font-body'; label = 'Body Font'; value = 'Flex2 Geist'; status = 'active'; type = 'fonts' },
	@{ id = 'gvid-flex2-font-mono'; label = 'Mono Font'; value = 'Flex2 Geist Mono'; status = 'active'; type = 'fonts' }
)

$customCss = @'
:root {
	color-scheme: dark;
}

html {
	scroll-behavior: smooth;
}

body,
body.et-db #main-content,
body.et-db #main-content #et-boc,
body.et-db #main-content #et-boc .et-l {
	background: var(--gcid-flex2-background);
	color: var(--gcid-flex2-foreground);
	font-family: var(--gvid-flex2-font-body), sans-serif;
}

body.et_divi_theme {
	background: var(--gcid-flex2-background);
}

.et_pb_section.fx2-header-section,
.et_pb_section.fx2-hero-section,
.et_pb_section.fx2-locations-section,
.et_pb_section.fx2-philosophy-section,
.et_pb_section.fx2-workflows-section,
.et_pb_section.fx2-benefits-section,
.et_pb_section.fx2-contact-section,
.et_pb_section.fx2-footer-section {
	background: transparent;
	padding: var(--gvid-flex2-space-section-y) 0;
}

.et_pb_section.fx2-header-section {
	position: sticky;
	top: 0;
	z-index: 50;
	padding: var(--gvid-flex2-space-header-y) 0;
	background: rgba(0, 0, 0, 0.82);
	backdrop-filter: blur(18px);
	-webkit-backdrop-filter: blur(18px);
	border-bottom: var(--gvid-flex2-border-width) solid var(--gcid-flex2-border);
}

.et_pb_section.fx2-hero-section {
	padding-top: clamp(6rem, 11vw, 9rem);
	padding-bottom: clamp(4rem, 8vw, 7rem);
	position: relative;
	overflow: clip;
}

.et_pb_section.fx2-hero-section::before {
	content: "";
	position: absolute;
	inset: auto auto -14rem -10rem;
	width: 30rem;
	height: 30rem;
	border-radius: 50%;
	background: radial-gradient(circle at center, rgba(250, 250, 250, 0.14), rgba(250, 250, 250, 0) 68%);
	filter: blur(18px);
	pointer-events: none;
}

.et_pb_section.fx2-hero-section::after {
	content: "";
	position: absolute;
	inset: 0;
	background-image: radial-gradient(rgba(250, 250, 250, 0.08) 1px, transparent 1px);
	background-size: 1.25rem 1.25rem;
	mask-image: linear-gradient(180deg, rgba(0, 0, 0, 0.5), transparent 72%);
	opacity: 0.45;
	pointer-events: none;
}

.et_pb_section.fx2-benefits-section,
.et_pb_section.fx2-contact-section {
	padding-top: var(--gvid-flex2-space-section-y-tight);
}

.et_pb_section.fx2-footer-section {
	padding-top: var(--gvid-flex2-space-section-y-tight);
	padding-bottom: clamp(2rem, 4vw, 3rem);
	border-top: var(--gvid-flex2-border-width) solid var(--gcid-flex2-border);
}

.et_pb_row.fx2-row {
	width: min(calc(100% - (2 * var(--gvid-flex2-space-site-gutter))), var(--gvid-flex2-max-width)) !important;
	max-width: none !important;
}

.et_pb_row.fx2-header-row,
.et_pb_row.fx2-philosophy-row,
.et_pb_row.fx2-contact-row,
.et_pb_row.fx2-locations-row,
.et_pb_row.fx2-workflow-cards-row,
.et_pb_row.fx2-stats-row,
.et_pb_row.fx2-footer-row {
	display: grid;
	gap: var(--gvid-flex2-space-grid-gap);
}

.et_pb_row.fx2-header-row {
	grid-template-columns: minmax(0, 14rem) minmax(0, 1fr);
	align-items: center;
}

.et_pb_row.fx2-philosophy-row,
.et_pb_row.fx2-contact-row,
.et_pb_row.fx2-footer-row {
	grid-template-columns: repeat(2, minmax(0, 1fr));
	align-items: start;
}

.et_pb_row.fx2-locations-row,
.et_pb_row.fx2-workflow-cards-row {
	grid-template-columns: repeat(3, minmax(0, 1fr));
}

.et_pb_row.fx2-stats-row {
	grid-template-columns: repeat(4, minmax(0, 1fr));
}

.et_pb_row.fx2-header-row > .et_pb_column,
.et_pb_row.fx2-philosophy-row > .et_pb_column,
.et_pb_row.fx2-contact-row > .et_pb_column,
.et_pb_row.fx2-locations-row > .et_pb_column,
.et_pb_row.fx2-workflow-cards-row > .et_pb_column,
.et_pb_row.fx2-stats-row > .et_pb_column,
.et_pb_row.fx2-footer-row > .et_pb_column {
	width: auto !important;
	margin: 0 !important;
}

.fx2-header-brand-col,
.fx2-header-nav-col,
.fx2-hero-col,
.fx2-philosophy-intro-col,
.fx2-philosophy-copy-col,
.fx2-contact-copy-col,
.fx2-contact-form-col {
	display: flex;
	flex-direction: column;
	justify-content: center;
}

.fx2-header-nav-col {
	flex-direction: row;
	flex-wrap: wrap;
	align-items: center;
	justify-content: flex-end;
	gap: 0.875rem 1.25rem;
}

.fx2-brand,
.fx2-nav,
.fx2-hero-badge,
.fx2-hero-title,
.fx2-hero-copy,
.fx2-service-note,
.fx2-section-intro,
.fx2-location-card,
.fx2-philosophy-copy,
.fx2-workflow-card,
.fx2-stat-card,
.fx2-contact-copy,
.fx2-footer-brand,
.fx2-footer-links {
	margin-bottom: 0 !important;
}

.fx2-brand .et_pb_text_inner,
.fx2-nav .et_pb_text_inner,
.fx2-footer-links .et_pb_text_inner {
	color: var(--gcid-flex2-foreground);
}

.fx2-brand a,
.fx2-nav a,
.fx2-footer-links a {
	color: inherit !important;
	text-decoration: none;
}

.fx2-brand a {
	font-size: 1.1rem;
	font-weight: 600;
	letter-spacing: -0.03em;
}

.fx2-nav .et_pb_text_inner {
	display: flex;
}

.fx2-nav-links {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	justify-content: flex-end;
	gap: 0.75rem 1.5rem;
	font-size: var(--gvid-flex2-font-size-nav);
	color: var(--gcid-flex2-text-secondary);
}

.fx2-nav-links a {
	position: relative;
	transition: color 0.2s ease;
}

.fx2-nav-links a::after {
	content: "";
	position: absolute;
	left: 0;
	bottom: -0.25rem;
	width: 100%;
	height: var(--gvid-flex2-border-width);
	background: currentColor;
	transform: scaleX(0);
	transform-origin: left center;
	transition: transform 0.2s ease;
}

.fx2-nav-links a:hover,
.fx2-nav-links a:focus-visible {
	color: var(--gcid-flex2-foreground);
}

.fx2-nav-links a:hover::after,
.fx2-nav-links a:focus-visible::after {
	transform: scaleX(1);
}

.fx2-primary-button.et_pb_button_module_wrapper {
	margin-bottom: 0 !important;
}

.fx2-primary-button .et_pb_button {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 0.5rem;
	padding: 0.95rem 1.35rem !important;
	border: 0 !important;
	border-radius: var(--gvid-flex2-radius-pill);
	background: var(--gcid-flex2-foreground);
	color: var(--gcid-flex2-background) !important;
	font-family: var(--gvid-flex2-font-body), sans-serif;
	font-size: var(--gvid-flex2-font-size-small);
	font-weight: 600;
	letter-spacing: 0.01em;
	line-height: 1;
	box-shadow: 0 0 0 0.125rem rgba(250, 250, 250, 0.08), 0 1.25rem 2.5rem rgba(255, 255, 255, 0.08);
	transition: transform 0.2s ease, box-shadow 0.2s ease, opacity 0.2s ease;
}

.fx2-primary-button .et_pb_button:hover,
.fx2-primary-button .et_pb_button:focus-visible {
	background: var(--gcid-flex2-foreground);
	color: var(--gcid-flex2-background) !important;
	transform: translateY(-0.125rem);
	box-shadow: 0 0 0 0.125rem rgba(250, 250, 250, 0.12), 0 1.5rem 3rem rgba(255, 255, 255, 0.12);
}

.fx2-hero-col {
	gap: var(--gvid-flex2-space-block-gap);
	min-height: min(48rem, calc(100svh - 8rem));
	align-items: flex-start;
}

.fx2-hero-badge .et_pb_text_inner,
.fx2-kicker {
	display: inline-flex;
	align-items: center;
	gap: 0.625rem;
	text-transform: uppercase;
	letter-spacing: 0.18em;
	font-size: var(--gvid-flex2-font-size-label);
	font-weight: 600;
	color: var(--gcid-flex2-text-subtle);
}

.fx2-hero-badge .et_pb_text_inner {
	padding: 0.65rem 0.9rem;
	border: var(--gvid-flex2-border-width) solid var(--gcid-flex2-border);
	border-radius: var(--gvid-flex2-radius-pill);
	background: rgba(250, 250, 250, 0.04);
}

.fx2-hero-title h1,
.fx2-section-intro h2,
.fx2-contact-copy h2 {
	margin: 0;
	color: var(--gcid-flex2-foreground);
	letter-spacing: -0.06em;
}

.fx2-hero-title h1 {
	font-size: var(--gvid-flex2-font-size-hero);
	line-height: var(--gvid-flex2-line-height-tight);
}

.fx2-hero-title h1 span {
	display: block;
}

.fx2-hero-copy .et_pb_text_inner,
.fx2-section-intro p:last-child,
.fx2-philosophy-copy .et_pb_text_inner,
.fx2-contact-copy .et_pb_text_inner {
	max-width: var(--gvid-flex2-copy-max-width);
	font-size: var(--gvid-flex2-font-size-body);
	line-height: 1.7;
	color: var(--gcid-flex2-text-secondary);
}

.fx2-section-intro .et_pb_text_inner {
	display: grid;
	gap: 1rem;
}

.fx2-section-intro h2,
.fx2-contact-copy h2 {
	font-size: var(--gvid-flex2-font-size-display);
	line-height: 1;
}

.fx2-service-note .et_pb_text_inner {
	font-size: var(--gvid-flex2-font-size-small);
	color: var(--gcid-flex2-text-subtle);
}

.fx2-locations-intro-row,
.fx2-workflows-intro-row,
.fx2-benefits-intro-row {
	margin-bottom: 1.5rem !important;
}

.fx2-location-card .et_pb_text_inner,
.fx2-workflow-card .et_pb_text_inner,
.fx2-stat-card .et_pb_text_inner,
.fx2-contact-form-wrap,
.fx2-footer-links .fx2-footer-meta {
	padding: var(--gvid-flex2-space-card-padding);
	border: var(--gvid-flex2-border-width) solid var(--gcid-flex2-border);
	border-radius: var(--gvid-flex2-radius-card);
	background: var(--gcid-flex2-surface);
}

.fx2-location-card .et_pb_text_inner {
	font-size: var(--gvid-flex2-font-size-body);
	font-weight: 500;
	color: var(--gcid-flex2-foreground);
	text-align: center;
}

.fx2-philosophy-copy .et_pb_text_inner,
.fx2-contact-copy .et_pb_text_inner {
	display: grid;
	gap: 1rem;
}

.fx2-philosophy-copy p,
.fx2-contact-copy p {
	margin: 0;
}

.fx2-workflow-card .et_pb_text_inner {
	display: grid;
	gap: 1rem;
	height: 100%;
	transition: transform 0.2s ease, background 0.2s ease, border-color 0.2s ease;
}

.fx2-workflow-card .et_pb_text_inner:hover {
	transform: translateY(-0.25rem);
	background: var(--gcid-flex2-surface-hover);
	border-color: rgba(250, 250, 250, 0.16);
}

.fx2-card-index {
	margin: 0;
	font-family: var(--gvid-flex2-font-mono), monospace;
	font-size: var(--gvid-flex2-font-size-small);
	letter-spacing: 0.18em;
	text-transform: uppercase;
	color: var(--gcid-flex2-text-subtle);
}

.fx2-workflow-card h3 {
	margin: 0;
	font-size: 1.4rem;
	line-height: 1.1;
	letter-spacing: -0.03em;
	color: var(--gcid-flex2-foreground);
}

.fx2-workflow-card p:last-child {
	margin: 0;
	font-size: var(--gvid-flex2-font-size-body);
	line-height: 1.7;
	color: var(--gcid-flex2-text-secondary);
}

.fx2-stat-card .et_pb_text_inner {
	display: grid;
	gap: 0.75rem;
	height: 100%;
}

.fx2-stat-value {
	margin: 0;
	font-size: var(--gvid-flex2-font-size-stat);
	line-height: 0.95;
	letter-spacing: -0.06em;
	color: var(--gcid-flex2-foreground);
}

.fx2-stat-label {
	margin: 0;
	font-size: var(--gvid-flex2-font-size-small);
	text-transform: uppercase;
	letter-spacing: 0.18em;
	color: var(--gcid-flex2-text-subtle);
}

.fx2-contact-row {
	align-items: center;
}

.fx2-contact-form-wrap {
	padding: clamp(1.5rem, 2vw, 2rem);
}

.fx2-contact-form-wrap .ff-default .ff-el-group,
.fx2-contact-form-wrap .ff-default .ff-el-input--content,
.fx2-contact-form-wrap .ff-default .ff-t-container,
.fx2-contact-form-wrap .ff_default .ff-el-group {
	margin-bottom: 1rem;
}

.fx2-contact-form-wrap .ff-el-input--label label,
.fx2-contact-form-wrap .ff-el-is-required.asterisk-right label::after,
.fx2-contact-form-wrap label {
	color: var(--gcid-flex2-text-subtle);
	font-size: var(--gvid-flex2-font-size-small);
	font-weight: 500;
}

.fx2-contact-form-wrap input,
.fx2-contact-form-wrap textarea,
.fx2-contact-form-wrap select,
.fx2-contact-form-wrap .ff-el-form-control {
	width: 100%;
	padding: 1rem 1.1rem;
	border: var(--gvid-flex2-border-width) solid var(--gcid-flex2-border);
	border-radius: 1rem;
	background: rgba(250, 250, 250, 0.03);
	color: var(--gcid-flex2-foreground);
	font-family: var(--gvid-flex2-font-body), sans-serif;
	font-size: var(--gvid-flex2-font-size-body);
	box-shadow: none;
}

.fx2-contact-form-wrap input::placeholder,
.fx2-contact-form-wrap textarea::placeholder {
	color: var(--gcid-flex2-text-tertiary);
}

.fx2-contact-form-wrap input:focus,
.fx2-contact-form-wrap textarea:focus,
.fx2-contact-form-wrap select:focus,
.fx2-contact-form-wrap .ff-el-form-control:focus {
	outline: none;
	border-color: rgba(250, 250, 250, 0.28);
	background: rgba(250, 250, 250, 0.05);
}

.fx2-contact-form-wrap .ff-btn,
.fx2-contact-form-wrap .ff-btn-submit,
.fx2-contact-form-wrap button[type="submit"],
.fx2-contact-form-wrap input[type="submit"] {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	min-height: 3.25rem;
	padding: 0.95rem 1.35rem;
	border: 0;
	border-radius: var(--gvid-flex2-radius-pill);
	background: var(--gcid-flex2-foreground);
	color: var(--gcid-flex2-background);
	font-family: var(--gvid-flex2-font-body), sans-serif;
	font-size: var(--gvid-flex2-font-size-small);
	font-weight: 600;
	line-height: 1;
	transition: transform 0.2s ease, box-shadow 0.2s ease, opacity 0.2s ease;
	box-shadow: 0 0 0 0.125rem rgba(250, 250, 250, 0.08), 0 1.25rem 2.5rem rgba(255, 255, 255, 0.08);
}

.fx2-contact-form-wrap .ff-btn:hover,
.fx2-contact-form-wrap .ff-btn-submit:hover,
.fx2-contact-form-wrap button[type="submit"]:hover,
.fx2-contact-form-wrap input[type="submit"]:hover {
	transform: translateY(-0.125rem);
}

.fx2-footer-brand .et_pb_text_inner {
	display: grid;
	gap: 0.5rem;
	max-width: 20rem;
	color: var(--gcid-flex2-text-secondary);
}

.fx2-footer-mark {
	margin: 0;
	font-size: 1.1rem;
	font-weight: 600;
	letter-spacing: -0.03em;
	color: var(--gcid-flex2-foreground);
}

.fx2-footer-meta {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	justify-content: flex-end;
	gap: 0.75rem 1.5rem;
	font-size: var(--gvid-flex2-font-size-small);
	color: var(--gcid-flex2-text-secondary);
}

.fx2-footer-meta span {
	opacity: 0.9;
}

@media (max-width: 980px) {
	.et_pb_section.fx2-header-section {
		position: static;
	}

	.et_pb_row.fx2-header-row,
	.et_pb_row.fx2-philosophy-row,
	.et_pb_row.fx2-contact-row,
	.et_pb_row.fx2-footer-row,
	.et_pb_row.fx2-locations-row,
	.et_pb_row.fx2-workflow-cards-row,
	.et_pb_row.fx2-stats-row {
		grid-template-columns: minmax(0, 1fr);
	}

	.fx2-header-nav-col,
	.fx2-footer-meta {
		justify-content: flex-start;
	}

	.fx2-hero-col {
		min-height: auto;
	}
}

@media (max-width: 767px) {
	.fx2-hero-section {
		padding-top: 5rem;
	}

	.fx2-primary-button .et_pb_button,
	.fx2-contact-form-wrap .ff-btn,
	.fx2-contact-form-wrap .ff-btn-submit,
	.fx2-contact-form-wrap button[type="submit"],
	.fx2-contact-form-wrap input[type="submit"] {
		width: 100%;
	}

	.fx2-nav-links {
		gap: 0.75rem 1rem;
	}
}
'@

$export = [ordered]@{
	context            = 'et_builder'
	data               = [ordered]@{ 'flex2next-homepage' = $layoutContent }
	presets            = @()
	global_colors      = $globalColors
	global_variables   = $globalVariables
	page_settings_meta = [ordered]@{ _et_pb_custom_css = $customCss }
	canvases           = [ordered]@{ local = @(); global = @() }
	images             = @()
	thumbnails         = @()
}

$json = $export | ConvertTo-Json -Depth 100
$json | Set-Content -Path $outputPath -Encoding UTF8

Get-Content -Path $outputPath -Raw | ConvertFrom-Json | Out-Null

Write-Output "Generated $outputPath"
