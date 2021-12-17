<?php if ( ! defined( 'ABSPATH' ) )  exit; ?>
<?php
	$caps = get_role( 'administrator' ); $s = $this->modules[$_GET['tab']]->settings;
	$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );
?>
			<h3><?php _e( 'Image Optimizer', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
				<tr>
					<th><?php _e( 'Enable Image Optimize', 'wp-kusanagi' ); ?></th>
					<td>
						<input type="hidden" name="image_optimizer[enable_image_optimize]" value="0">
						<label for="enable_image_optimize">
							<input type="checkbox" id="enable_image_optimize" name="image_optimizer[enable_image_optimize]" value="1"<?php echo 1 == $s['image_optimizer']['enable_image_optimize'] ? ' checked="checked"' : ''; ?>>
							<?php _e( 'Enable', 'wp-kusanagi' ); ?>
						</label>
					</td>
				</tr>
				<tr>
					<th><?php _e( 'Jpeg quality', 'wp-kusanagi' ); ?></th>
					<td><div id="jpeg_quality_slider"><span id="quality-value"><?php echo esc_html( $s['image_optimizer']['jpeg_quality'] ); ?></span></div>
					<input type="hidden" id="jpeg_quality" name="image_optimizer[jpeg_quality]" value="<?php echo esc_attr( $s['image_optimizer']['jpeg_quality'] ); ?>">
					</td>
				</tr>
				<tr>
					<th><?php _e( 'Max full image widh', 'wp-kusanagi' ); ?></th>
					<td><input type="number" name="image_optimizer[max_image_width]" value="<?php echo esc_attr( $s['image_optimizer']['max_image_width'] ); ?>"> px
					<br><?php _e( '* larger than 320px', 'wp-kusanagi' ); ?>
					</td>
				</tr>
			</table>

			<h3><?php _e( 'Replacing', 'wp-kusanagi' ); ?></h3>

			<table class="form-table">
			<tr>
				<th><?php _e( 'Replacing at login/signup page', 'wp-kusanagi' ); ?></th>
				<td>
					<label for="replace_login-1">
						<input type="radio" id="replace_login-1" name="site_cache_life[replace_login]" value="1"<?php echo $life_time['replace_login'] ? ' checked="checked"' : ''; ?>>
						<?php _e( 'Yes', 'wp-kusanagi' ); ?>
					</label>
					<label for="replace_login-0">
						<input type="radio" id="replace_login-0" name="site_cache_life[replace_login]" value="0"<?php echo $life_time['replace_login'] ? '' : ' checked="checked"'; ?>>
						<?php _e( 'No', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Replacement string', 'wp-kusanagi' ); ?></th>
				<td>
					<table id="replaces-table">
						<tr class="replace-head">
							<th><?php _e( 'Target string', 'wp-kusanagi' ); ?></th>
							<th><?php _e( 'Replacement string', 'wp-kusanagi' ); ?></th>
							<th>&nbsp;</th>
						</tr>
<?php $key = -1; if ( isset( $life_time['replaces'] ) && is_array( $life_time['replaces'] ) ) :
	foreach ( $life_time['replaces'] as $key => $rule ) : ?>
						<tr id="replaces-row-<?php echo esc_attr( $key ); ?>" class="replace-row">
							<td>
								<textarea name="site_cache_life[replaces][<?php echo esc_attr( $key ); ?>][target]" size="15" rows="3"><?php echo esc_html( $rule['target'] ); ?></textarea>
							</td>
							<td>
								<textarea name="site_cache_life[replaces][<?php echo esc_attr( $key ); ?>][replace]" size="15" rows="3"><?php echo esc_html( $rule['replace'] ); ?></textarea>
							</td>
							<td>
								<a href="#" class="button" onclick="delete_rule(<?php echo esc_attr( $key ); ?>); return false;"><?php _e( 'Delete Rule', 'wp-kusanagi' ); ?></a>
							</td>
						</tr>
<?php	
	endforeach;
endif ?>
						<tr id="replaces-row-<?php echo esc_attr( $key + 1 ); ?>" class="replace-row">
							<td>
								<textarea name="site_cache_life[replaces][<?php echo esc_attr( $key + 1 ); ?>][target]" size="15" rows="3"></textarea>
							</td>
							<td>
								<textarea name="site_cache_life[replaces][<?php echo esc_attr( $key + 1 ); ?>][replace]" size="15" rows="3"></textarea>
							</td>
							<td>
								<a href="#" class="button" onclick="delete_rule(<?php echo esc_attr( $key + 1 ); ?>); return false;"><?php _e( 'Delete Rule', 'wp-kusanagi' ); ?></a>
							</td>
						</tr>
					</table>
					<a href="#" class="button" onclick="add_rule(); return false;"><?php _e( 'Add New Rule', 'wp-kusanagi' ); ?></a>
				</td>
			</tr>
			</table>
			
			<h3><?php _e( 'Performance Viewer', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
			<tr>
				<th><?php _e( 'Display performance on admin-bar.', 'wp-kusanagi' ); ?></th>
				<td>
					<input type="hidden" name="kusanagi-performance-viewer[enable]" value="0">
					<label for="performace-viewer-enable">
						<input type="checkbox" name="kusanagi-performance-viewer[enable]" id="performace-viewer-enable" value="1"<?php echo $s['performance-viewer']['enable'] ? ' checked="checked"' : ''; ?>>
						<?php _e( 'Enable', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Requierd capability to display performance', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="kusanagi-performance-viewer[capability]">
<?php foreach ( $caps->capabilities as $cap => $has ) : ?>
						<option value="<?php echo esc_attr( $cap ); ?>"<?php echo $cap == $s['performance-viewer']['capability'] ? ' selected="selected"' : ''; ?>><?php echo esc_html( $cap ); ?></option>
<?php endforeach; ?>
					</select>
				</td>
			</tr>
			</table>

			<h3><?php _e( 'Optimize wp-settings.php', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
			<tr>
				<th><?php _e( 'Optimize wp-settings.php', 'wp-kusanagi' ); ?></th>
				<td>
					<input type="hidden" name="opt-wp-settings[enable]" value="0">
					<label for="opt-wp-settings-enable">
						<input type="checkbox" name="opt-wp-settings[enable]" id="opt-wp-settings-enable" value="1"<?php echo $s['opt-wp-settings']['enable'] ? ' checked="checked"' : ''; ?>>
						<?php _e( 'Enable', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
			</table>

