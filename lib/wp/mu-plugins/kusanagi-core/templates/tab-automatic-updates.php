<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// phpcs:disable WordPress.WP.I18n.NonSingularStringLiteralText
$this->form_submit = false;
$current_module    = $this->modules[ sanitize_text_field( $_GET['tab'] ) ];
$settings          = $current_module->settings;
$schedule_settings = $current_module->schedule_settings;
$current_module->check_update_errors();

$show_autoupdates = false;
if ( function_exists( 'wp_is_auto_update_enabled_for_type' ) ) {
	$show_autoupdates = true;
	$update_lists     = $current_module->get_update_list();
}
$error_messages = $current_module->get_errors();
?>
<?php if ( ! current_user_can( 'update_core' ) && ! current_user_can( 'update_themes' ) && ! current_user_can( 'update_plugins' ) && ! current_user_can( 'update_languages' ) ) : ?>
	<div id="message" class="error">
		<p><?php esc_html_e( 'You don\'t have permission to update.', 'wp-kusanagi' ); ?></p>
	</div>
<?php else : ?>
	<?php if ( $error_messages ) : ?>
		<div id="message" class="error">
			<?php foreach ( $error_messages as $error_message ) : ?>
				<p>
					<?php
					// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
					echo $error_message;
					?>
				</p>
			<?php endforeach; ?>
		</div>
	<?php endif; ?>
	<h3><?php esc_html_e( 'Automatic Updates', 'wp-kusanagi' ); ?></h3>
	<table class="form-table">
		<tr>
			<th><?php echo esc_html_x( 'Translations', 'automatic updates', 'wp-kusanagi' ); ?></th>
			<td>
				<select name="translation">
					<option value="disable" <?php selected( $settings['translation'], 'disable' ); ?>><?php echo esc_html_x( 'Disable', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="enable" <?php selected( $settings['translation'], 'enable' ); ?>><?php echo esc_html_x( 'Enable - Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
				</select>
			</td>
		</tr>
		<tr>
			<th><?php echo esc_html_x( 'Plugins', 'automatic updates', 'wp-kusanagi' ); ?></th>
			<td>
				<select name="plugin">
					<option value="disable" <?php selected( $settings['plugin'], 'disable' ); ?>><?php echo esc_html_x( 'Disable all - KUSANAGI Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="individually" <?php selected( $settings['plugin'], 'individually' ); ?>><?php echo esc_html_x( 'Set individually - WordPress Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="enable" <?php selected( $settings['plugin'], 'enable' ); ?>><?php echo esc_html_x( 'Enable all', 'automatic updates', 'wp-kusanagi' ); ?></option>
				</select>
			</td>
		</tr>
		<tr>
			<th><?php echo esc_html_x( 'Themes', 'automatic updates', 'wp-kusanagi' ); ?></th>
			<td>
				<select name="theme">
					<option value="disable" <?php selected( $settings['theme'], 'disable' ); ?>><?php echo esc_html_x( 'Disable all - KUSANAGI Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="individually" <?php selected( $settings['theme'], 'individually' ); ?>><?php echo esc_html_x( 'Set individually - WordPress Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="enable" <?php selected( $settings['theme'], 'enable' ); ?>><?php echo esc_html_x( 'Enable all', 'automatic updates', 'wp-kusanagi' ); ?></option>
				</select>
			</td>
		</tr>
		<tr>
			<th><?php echo esc_html_x( 'WordPress core', 'automatic updates', 'wp-kusanagi' ); ?></th>
			<td>
				<select name="core">
					<option value="disable" <?php selected( $settings['core'], 'disable' ); ?>><?php echo esc_html_x( 'Disable all', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="minor" <?php selected( $settings['core'], 'minor' ); ?>><?php echo esc_html_x( 'Enable minor updates - KUSANAGI Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
					<option value="enable" <?php selected( $settings['core'], 'enable' ); ?>><?php echo esc_html_x( 'Enable major updates - WordPress Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
				</select>
			</td>
		</tr>
		<tr>
			<th><?php echo esc_html_x( 'Automatic update schedule', 'automatic updates', 'wp-kusanagi' ); ?></th>
			<td>
				<input type="checkbox" id="schedule" name="schedule" value="enable" <?php checked( $schedule_settings['schedule'], 'enable' ); ?>><label for="schedule"><?php echo esc_html_x( 'Enable schedule settings', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<p><?php echo esc_html_x( '* If this field is unchecked, Automatic updates will be performed with the default schedule.', 'automatic updates', 'wp-kusanagi' ); ?></p>
			</td>
		</tr>
		<tr>
			<th></th>
			<td>
				<input type="checkbox" id="week_day_0" name="week_day[]" value="week_day_0" <?php echo esc_html( in_array( 'week_day_0', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_0"><?php echo esc_html_x( 'Sunday', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<input type="checkbox" id="week_day_1" name="week_day[]" value="week_day_1" <?php echo esc_html( in_array( 'week_day_1', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_1"><?php echo esc_html_x( 'Monday', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<input type="checkbox" id="week_day_2" name="week_day[]" value="week_day_2" <?php echo esc_html( in_array( 'week_day_2', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_2"><?php echo esc_html_x( 'Tuesday', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<input type="checkbox" id="week_day_3" name="week_day[]" value="week_day_3" <?php echo esc_html( in_array( 'week_day_3', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_3"><?php echo esc_html_x( 'Wednesday', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<input type="checkbox" id="week_day_4" name="week_day[]" value="week_day_4" <?php echo esc_html( in_array( 'week_day_4', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_4"><?php echo esc_html_x( 'Thursday', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<input type="checkbox" id="week_day_5" name="week_day[]" value="week_day_5" <?php echo esc_html( in_array( 'week_day_5', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_5"><?php echo esc_html_x( 'Friday', 'automatic updates', 'wp-kusanagi' ); ?></label>
				<input type="checkbox" id="week_day_6" name="week_day[]" value="week_day_6" <?php echo esc_html( in_array( 'week_day_6', $schedule_settings['week_day'], true ) ? 'checked="checked"' : '' ); ?>><label for="week_day_6"><?php echo esc_html_x( 'Saturday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			</td>
		</tr>
		<tr>
			<th></th>
			<td>
				<select name="hour">
					<?php for ( $hh = 0; $hh <= 23; ++$hh ) : ?>
					<option value="<?php echo esc_attr( $hh ); ?>" <?php selected( $schedule_settings['hour'], $hh ); ?>><?php echo esc_html( $hh ); ?></option>
					<?php endfor; ?>
				</select><?php esc_html_e( 'Hour' ); ?>
				<select name="min">
					<?php for ( $min = 0; $min <= 59; ++$min ) : ?>
					<option value="<?php echo esc_attr( $min ); ?>" <?php selected( $schedule_settings['min'], $min ); ?>><?php echo esc_html( $min ); ?></option>
					<?php endfor; ?>
				</select><?php esc_html_e( 'Minute' ); ?>
			</td>
		</tr>
	</table>
	<?php submit_button( false, 'primary', 'update-kusanagi-settings' ); ?>
	<?php if ( $show_autoupdates ) : ?>
	<h2><?php esc_html_e( 'Automatic updates status of themes and plugins in use', 'wp-kusanagi' ); ?></h2>
	<p>
		<?php
		// phpcs:ignore WordPress.WP.I18n.MissingTranslatorsComment
		printf( esc_html__( 'To set up individual plugin updates, please go to the %1$s.', 'wp-kusanagi' ), sprintf( '<a href="%1$s">%2$s</a>', esc_url( '/wp-admin/plugins.php' ), esc_html__( 'Plugins page', 'wp-kusanagi' ) ) );
		?>
	</p>
	<p>
		<?php
		// phpcs:ignore WordPress.WP.I18n.MissingTranslatorsComment
		printf( esc_html__( 'To set up individual theme updates, please go to the %1$s.', 'wp-kusanagi' ), sprintf( '<a href="%1$s">%2$s</a>', esc_url( '/wp-admin/themes.php' ), esc_html__( 'Themes page', 'wp-kusanagi' ) ) );
		?>
	</p>
	<table class="wp-list-table widefat striped table-view-list" id="updates-table">
		<thead>
			<tr>
				<td class="manage-column"><?php esc_html_e( 'Name', 'wp-kusanagi' ); ?></td>
				<td class="manage-column"><?php esc_html_e( 'Type', 'wp-kusanagi' ); ?></td>
				<td class="manage-column"><?php esc_html_e( 'Automatic Updates', 'wp-kusanagi' ); ?></td>
			</tr>
		</thead>
		<tbody>
			<?php foreach ( $update_lists as $data ) : ?>
				<tr>
					<td><?php echo esc_html( $data['name'] ); ?></td>
					<td><?php esc_html_e( $data['type'] ); ?></td>
					<td>
					<?php
					if ( $data['autoupdate']['supported'] ) {
						if ( $data['autoupdate']['enabled'] ) {
							echo '<span class="enable">' . esc_html_x( 'Enabled', 'automatic updates', 'wp-kusanagi' ) . '</span>';
						} else {
							echo '<span class="disable">' . esc_html_x( 'Disabled', 'automatic updates', 'wp-kusanagi' ) . '</span>';
						}
					} else {
						echo '<span class="not-supported">' . esc_html_x( 'Not supported', 'automatic updates', 'wp-kusanagi' ) . '</span>';
					}
					?>
					</td>
				</tr>
			<?php endforeach; ?>
		</tbody>
	</table>
	<?php endif; ?>
<?php endif; ?>
