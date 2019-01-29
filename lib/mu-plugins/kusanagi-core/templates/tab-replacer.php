<?php
	if ( ! defined( 'ABSPATH' ) ) exit; 

	$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );
?>
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

