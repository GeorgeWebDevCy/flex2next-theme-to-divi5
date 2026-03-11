<?php
/**
 * Template Part: Workflows
 * Section: Dark inverted section with headline and ACF repeater of workflow cards.
 */
?>

<section id="workflows" class="py-32 px-6 bg-inverted-bg text-inverted-fg">
  <div class="max-w-7xl mx-auto text-center mb-24">

    <h2 class="text-5xl md:text-7xl font-bold tracking-tighter mb-6 text-inverted-fg">
      Absolute Automation.
    </h2>

    <p class="text-xl md:text-2xl text-inverted-muted max-w-2xl mx-auto font-light py-6">
      <?php the_field('workflows_intro'); ?>
    </p>

    <?php if ( have_rows('workflow_items') ) : ?>
      <div class="grid md:grid-cols-3 gap-8 text-left mt-24">
        <?php while ( have_rows('workflow_items') ) : the_row(); ?>
          <div class="p-10 rounded-3xl bg-inverted-surface hover:bg-inverted-surface-hover transition-colors h-full">

            <?php $svg_code = get_sub_field('icon_svg'); ?>
            <?php if ( $svg_code ) : ?>
              <div class="w-10 h-10 mb-8 text-inverted-fg" aria-hidden="true">
                <?php echo $svg_code; ?>
              </div>
            <?php endif; ?>

            <h4 class="text-2xl font-bold mb-4 tracking-tight text-inverted-fg">
              <?php the_sub_field('title'); ?>
            </h4>
            <p class="text-inverted-muted leading-relaxed">
              <?php the_sub_field('description'); ?>
            </p>

          </div>
        <?php endwhile; ?>
      </div>
    <?php endif; ?>

  </div>
</section>
