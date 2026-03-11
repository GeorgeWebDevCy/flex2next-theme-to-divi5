<?php
/**
 * Template Part: Benefits
 * Section: Stats grid showing key business outcomes.
 *
 * Stats are pulled from ACF fields with hardcoded fallbacks.
 * Expected ACF fields: benefit_items (repeater) with sub-fields: value, label
 */

$default_stats = [
  [ 'value' => '90%', 'label' => 'Time Saved' ],
  [ 'value' => '24/7', 'label' => 'Continuous Output' ],
  [ 'value' => '60%', 'label' => 'Overhead Reduction' ],
  [ 'value' => '∞',   'label' => 'Scalability' ],
];

$stats      = have_rows('benefit_items') ? [] : $default_stats;
$stat_count = 0;

if ( have_rows('benefit_items') ) {
  while ( have_rows('benefit_items') ) {
    the_row();
    $stats[] = [
      'value' => get_sub_field('value'),
      'label' => get_sub_field('label'),
    ];
  }
}

$total = count( $stats );
?>

<section id="benefits" class="py-32 px-6 border-b border-border">
  <div class="max-w-7xl mx-auto text-center">

    <p class="text-sm font-mono text-text-subtle uppercase tracking-widest mb-8">The Bottom Line</p>

    <p class="text-4xl md:text-6xl font-bold tracking-tighter mb-24 leading-tight text-foreground text-balance">
      We don't sell software. We sell
      <span class="text-transparent bg-clip-text bg-gradient-to-r from-foreground to-muted-foreground">time and money.</span>
    </p>

    <ul class="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-4 border-y border-border py-16 list-none m-0 p-0">
      <?php foreach ( $stats as $i => $stat ) :
        $is_last   = ( $i === $total - 1 );
        $border    = $is_last ? '' : 'md:border-r md:border-border';
      ?>
        <li class="flex flex-col items-center justify-center <?php echo esc_attr( $border ); ?>">
          <span class="text-5xl md:text-7xl font-bold tracking-tighter mb-2 text-foreground">
            <?php echo esc_html( $stat['value'] ); ?>
          </span>
          <span class="text-sm text-text-subtle uppercase tracking-wider font-mono">
            <?php echo esc_html( $stat['label'] ); ?>
          </span>
        </li>
      <?php endforeach; ?>
    </ul>

  </div>
</section>
