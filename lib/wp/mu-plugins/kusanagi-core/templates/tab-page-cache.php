<?php
if ( ! defined( 'ABSPATH' ) || ! isset( $this->modules['page-cache'] ) ) {
	exit;
}

$life_time           = get_option(
	'site_cache_life',
	array(
		'home'               => 60,
		'archive'            => 60,
		'singular'           => 360,
		'exclude'            => '',
		'allowed_query_keys' => '',
		'update'             => 'none',
		'replaces'           => array(),
		'replace_login'      => 0,
	)
);
$clear_link          = add_query_arg( array( 'del_cache' => '1' ) );
$advanced_cache_link = add_query_arg( array( 'generate_advanced_cache' => '1' ) );
$advanced_check      = $this->modules['page-cache']->check_advanced_cache_file();
?>
<h3><?php esc_html_e( 'Page Cache', 'wp-kusanagi' ); ?></h3>
<?php if ( ! ( defined( 'WP_CACHE' ) && WP_CACHE ) ) : ?>
<div class="updated"> 
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'The page cache system is not enabled. If you want to enable it, please input <code>kusanagi bcache on</code> on virtual machine console.', 'wp-kusanagi' );
		?>
	</p>
</div> 
<?php endif; ?>
<?php if ( is_wp_error( $advanced_check ) ) : ?>
<div class="updated"> 
	<p><?php echo esc_html( $advanced_check->get_error_message( 'cache-file-error' ) ); ?></p>
</div> 
<?php endif; ?>
	<table class="form-table">
		<tr>
			<th><?php esc_html_e( 'Front page', 'wp-kusanagi' ); ?></th>
			<td>
				<input type="number" size="2" name="site_cache_life[home]" value="<?php echo esc_attr( $life_time['home'] ); ?>" /> <?php esc_html_e( 'minutes', 'wp-kusanagi' ); ?>
			</td>
		</tr>
		<tr>
			<th><?php esc_html_e( 'Archives', 'wp-kusanagi' ); ?></th>
			<td>
				<input type="number" size="2" name="site_cache_life[archive]" value="<?php echo esc_attr( $life_time['archive'] ); ?>" /> <?php esc_html_e( 'minutes', 'wp-kusanagi' ); ?>
			</td>
		</tr>
		<tr>
			<th><?php esc_html_e( 'Article', 'wp-kusanagi' ); ?></th>
			<td>
				<input type="number" size="2" name="site_cache_life[singular]" value="<?php echo esc_attr( $life_time['singular'] ); ?>" /> <?php esc_html_e( 'minutes', 'wp-kusanagi' ); ?>
			</td>
		</tr>
		<tr>
			<th><?php esc_html_e( 'Cache excluded URL', 'wp-kusanagi' ); ?></th>
			<td>
				<textarea cols="70" rows="5" name="site_cache_life[exclude]"><?php echo esc_html( $life_time['exclude'] ); ?></textarea>
				<p class="description"><?php esc_html_e( 'You can specify a URL pattern (regular expression is available) that you want to exclude the cache. If you specify multiple patterns, please insert line feeds.', 'wp-kusanagi' ); ?></p>
			</td>
		</tr>
		<tr>
			<th><?php esc_html_e( 'Query string to cache', 'wp-kusanagi' ); ?></th>
			<td>
				<textarea cols="10" rows="5" name="site_cache_life[allowed_query_keys]"><?php echo esc_html( $life_time['allowed_query_keys'] ); ?></textarea>
				<p class="description"><?php esc_html_e( 'Please enter a key of valid query string as a cache data.', 'wp-kusanagi' ); ?></p>
			</td>
		</tr>

</table>
<h3><?php esc_html_e( 'Range of cache to delete when publishing articles', 'wp-kusanagi' ); ?></h3>
	<select name="site_cache_life[update]">
		<option value="none"<?php echo 'none' === $life_time['update'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Do not delete', 'wp-kusanagi' ); ?></option>
		<option value="single"<?php echo 'single' === $life_time['update'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Article only', 'wp-kusanagi' ); ?></option>
		<option value="with-front"<?php echo 'with-front' === $life_time['update'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Article and front page', 'wp-kusanagi' ); ?></option>
		<option value="all"<?php echo 'all' === $life_time['update'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'All', 'wp-kusanagi' ); ?></option>
	</select>

<?php if ( apply_filters( 'allow_sitemanager_cache_clear', true ) ) : ?>
<h3><?php esc_html_e( 'Clear Cache', 'wp-kusanagi' ); ?></h3>
<a href="<?php echo esc_url( $clear_link ); ?>" class="button"><?php esc_html_e( 'Clear all caches', 'wp-kusanagi' ); ?></a>
<?php endif; ?>

<?php if ( apply_filters( 'allow_generate_advanced_cache', true ) ) : ?>
<h3><?php esc_html_e( 'Regeneration of advanced-cache.php', 'wp-kusanagi' ); ?></h3>
	<?php if ( $this->modules['page-cache']->is_writable_advanced_cache_file() ) : ?>
	<a href="<?php echo esc_url( $advanced_cache_link ); ?>" class="button"><?php esc_html_e( 'Regenerate advanced-cache.php', 'wp-kusanagi' ); ?></a>
	<?php else : ?>
	<p>
		<?php
		// phpcs:ignore WordPress.WP.I18n.MissingTranslatorsComment
		esc_html( sprintf( __( 'You do not have a write permission to write in advanced-cache.php or %1s. To regenerate advanced-cache.php, please set the write permission.', 'wp-kusanagi' ), basename( WP_CONTENT_DIR ) ) );
		?>
	</p>
	<?php endif; ?>
<?php endif; ?>
