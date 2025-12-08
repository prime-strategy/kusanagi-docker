<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$settings          = $this->modules[ sanitize_text_field( $_GET['tab'] ) ]->settings;
$cache_mode_enable = $this->modules[ sanitize_text_field( $_GET['tab'] ) ]->cache_mode_enable;
$cache_clear_link  = add_query_arg(
	array(
		'cache_force_delete'              => '1',
		'_translation_delete_cache_nonce' => wp_create_nonce( 'translate_accelerator_delete_cache_action' ),
	)
);
?>
			<h3><?php esc_html_e( 'Translate Accelerator', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
			<tr>
				<th><?php esc_html_e( 'Enable Translate Accelerator', 'wp-kusanagi' ); ?></th>
				<td>
					<label for="activate">
						<input type="checkbox" name="activate" id="activate" value="1"<?php echo '1' === $settings['activate'] ? ' checked="checked"' : ''; ?> />
						<?php esc_html_e( 'Enable', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
<?php if ( $cache_mode_enable ) : ?>
			<tr>
				<th><?php esc_html_e( 'Type', 'wp-kusanagi' ); ?></th>
				<td>
					<ul>
						<li><label for="cache_type_file"><input type="radio" name="cache_type" id="cache_type_file" value="file"<?php echo 'file' === $settings['cache_type'] || ( 'apc' === $settings['cache_type'] && ! function_exists( 'apc_store' ) && ! function_exists( 'apcu_store' ) ) ? ' checked="checked"' : ''; ?> /> <?php esc_html_e( 'Files', 'wp-kusanagi' ); ?></label><br />
							<?php esc_html_e( 'Cache directory :', 'wp-kusanagi' ); ?> <input type="text" size="50" name="file_cache_dir" value="<?php echo esc_html( $settings['file_cache_dir'] ); ?>" />
						</li>
	<?php if ( function_exists( 'apc_store' ) || function_exists( 'apcu_store' ) ) : ?>
						<li><label for="cache_type_apc"><input type="radio" name="cache_type" id="cache_type_apc" value="apc"<?php echo 'apc' === $settings['cache_type'] ? ' checked="checked"' : ''; ?> /><?php esc_html_e( 'APC', 'wp-kusanagi' ); ?></label></li>
	<?php endif; ?>
					</ul>
				</td>
			</tr>
<?php endif; ?>
			<tr>
				<th><?php esc_html_e( 'Translated text displayed in your site', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="frontend">
						<option value="cutoff"<?php echo 'cutoff' === $settings['frontend'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Disable translation', 'wp-kusanagi' ); ?></option>
						<option value="default"<?php echo 'default' === $settings['frontend'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( "Use language file's for translation", 'wp-kusanagi' ); ?></option>
<?php if ( $cache_mode_enable ) : ?>
						<option value="cache"<?php echo 'cache' === $settings['frontend'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Enable cache', 'wp-kusanagi' ); ?></option>
<?php endif; ?>
					</select>
				</td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Login/signup page translation', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="wp-login">
						<option value="cutoff"<?php echo 'cutoff' === $settings['wp-login'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Disable translation', 'wp-kusanagi' ); ?></option>
						<option value="default"<?php echo 'default' === $settings['wp-login'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( "Use language file's for translation", 'wp-kusanagi' ); ?></option>
<?php if ( $cache_mode_enable ) : ?>
						<option value="cache"<?php echo 'cache' === $settings['wp-login'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Enable cache', 'wp-kusanagi' ); ?></option>
<?php endif; ?>
					</select>
				</td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Admin pages translation', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="admin">
						<option value="cutoff"<?php echo 'cutoff' === $settings['admin'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Disable translation', 'wp-kusanagi' ); ?></option>
						<option value="default"<?php echo 'default' === $settings['admin'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( "Use language file's for translation", 'wp-kusanagi' ); ?></option>
<?php if ( $cache_mode_enable ) : ?>
						<option value="cache"<?php echo 'cache' === $settings['admin'] ? ' selected="selected"' : ''; ?>><?php esc_html_e( 'Enable cache', 'wp-kusanagi' ); ?></option>
<?php endif; ?>
					</select>
				</td>
			</tr>
		</table>
		<?php wp_nonce_field( 'translate_accelerator_settings_action', '_translation_settings_nonce' ); ?>
<?php if ( $cache_mode_enable ) : ?>
		<h3><?php esc_html_e( 'Delete cache', 'wp-kusanagi' ); ?></h3>
		<a href="<?php echo esc_url( $cache_clear_link ); ?>" class="button"><?php esc_html_e( 'Force deletion of all cache', 'wp-kusanagi' ); ?></a>
<?php endif; ?>
