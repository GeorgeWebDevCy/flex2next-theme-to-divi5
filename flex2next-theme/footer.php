<footer class="py-12 px-6 border-t border-border bg-background">
  <div class="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
    <div class="flex items-center gap-2">
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
        class="lucide lucide-command w-5 h-5 text-text-subtle" aria-hidden="true">
        <path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"></path>
      </svg>
      <span class="text-lg font-bold tracking-tighter text-text-subtle">
        <?php bloginfo('name'); ?>
      </span>
    </div>

    <div class="text-sm text-text-tertiary text-center md:text-left">
      © <?php echo date('Y'); ?> <?php the_field('company_name', 'options'); ?>. All rights reserved.
    </div>

    <div class="flex gap-6 text-sm text-text-tertiary">
      <a href="<?php echo get_privacy_policy_url(); ?>" class="hover:text-foreground transition-colors">Privacy
        Policy</a>
      <a href="#" class="hover:text-foreground transition-colors">Terms of Service</a>
    </div>
  </div>
</footer>

</div> <?php wp_footer(); ?>
</body>

</html>