<?php
if ( ! defined( 'ABSPATH' ) ) exit;

$current_module = $this->modules[$_GET['tab']];
$s = $current_module->settings;
$ss = $current_module->schedule_settings;
$current_module->check_filesystem();
?>
<?php if ( $errors = $current_module->get_errors() ) : ?>
	<div id="message" class="error">
		<?php foreach ( $errors as $error ) : ?>
			<p><?php echo $error; ?></p>
		<?php endforeach; ?>
	</div>
<?php endif; ?>
<h3><?php _e( 'Automatic Updates', 'wp-kusanagi' ); ?></h3>
<table class="form-table">
	<tr>
		<th><?php _ex( 'Translations', 'automatic updates', 'wp-kusanagi' ); ?></th>
		<td>
			<select name="translation">
				<option value="disable" <?php selected( $s['translation'], 'disable' ); ?>><?php _ex( 'Disable', 'automatic updates', 'wp-kusanagi' ); ?></option>
				<option value="enable" <?php selected( $s['translation'], 'enable' ); ?>><?php _ex( 'Enable - Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
			</select>
		</td>
	</tr>
	<tr>
		<th><?php _ex( 'Plugins', 'automatic updates', 'wp-kusanagi' ); ?></th>
		<td>
			<select name="plugin">
				<option value="disable" <?php selected( $s['plugin'], 'disable' ); ?>><?php _ex( 'Disable - Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
				<option value="enable" <?php selected( $s['plugin'], 'enable' ); ?>><?php _ex( 'Enable', 'automatic updates', 'wp-kusanagi' ); ?></option>
			</select>
		</td>
	</tr>
	<tr>
		<th><?php _ex( 'Themes', 'automatic updates', 'wp-kusanagi' ); ?></th>
		<td>
			<select name="theme">
				<option value="disable" <?php selected( $s['theme'], 'disable' ); ?>><?php _ex( 'Disable - Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
				<option value="enable" <?php selected( $s['theme'], 'enable' ); ?>><?php _ex( 'Enable', 'automatic updates', 'wp-kusanagi' ); ?></option>
			</select>
		</td>
	</tr>
	<tr>
		<th><?php _ex( 'WordPress core', 'automatic updates', 'wp-kusanagi' ); ?></th>
		<td>
			<select name="core">
				<option value="disable" <?php selected( $s['core'], 'disable' ); ?>><?php _ex( 'Disable all core updates', 'automatic updates', 'wp-kusanagi' ); ?></option>
				<option value="minor" <?php selected( $s['core'], 'minor' ); ?>><?php _ex( 'Enable only core minor updates - Default', 'automatic updates', 'wp-kusanagi' ); ?></option>
				<option value="enable" <?php selected( $s['core'], 'enable' ); ?>><?php _ex( 'Enable all core updates', 'automatic updates', 'wp-kusanagi' ); ?></option>
			</select>
		</td>
	</tr>
	<tr>
		<th><?php _ex( 'Automatic update schedule', 'automatic updates', 'wp-kusanagi' ); ?></th>
		<td>
			<input type="checkbox" id="schedule" name="schedule" value="enable" <?php checked( $ss['schedule'], 'enable' ); ?>><label for="schedule"><?php echo _x( 'Enable schedule settings', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<p><?php _ex( '* If this field is unchecked, Automatic updates will be performed with the default schedule.', 'automatic updates', 'wp-kusanagi' ); ?></p>
		</td>
	</tr>
	<tr>
		<th></th>
		<td>
			<input type="checkbox" id="week_day_0" name="week_day[]" value="week_day_0" <?php echo in_array( 'week_day_0', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_0"><?php _ex( 'Sunday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<input type="checkbox" id="week_day_1" name="week_day[]" value="week_day_1" <?php echo in_array( 'week_day_1', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_1"><?php _ex( 'Monday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<input type="checkbox" id="week_day_2" name="week_day[]" value="week_day_2" <?php echo in_array( 'week_day_2', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_2"><?php _ex( 'Tuesday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<input type="checkbox" id="week_day_3" name="week_day[]" value="week_day_3" <?php echo in_array( 'week_day_3', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_3"><?php _ex( 'wednesday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<input type="checkbox" id="week_day_4" name="week_day[]" value="week_day_4" <?php echo in_array( 'week_day_4', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_4"><?php _ex( 'Thursday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<input type="checkbox" id="week_day_5" name="week_day[]" value="week_day_5" <?php echo in_array( 'week_day_5', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_5"><?php _ex( 'Friday', 'automatic updates', 'wp-kusanagi' ); ?></label>
			<input type="checkbox" id="week_day_6" name="week_day[]" value="week_day_6" <?php echo in_array( 'week_day_6', $ss['week_day'] ) ? 'checked="checked"' : ''; ?>><label for="week_day_6"><?php _ex( 'Saturday', 'automatic updates', 'wp-kusanagi' ); ?></label>
		</td>
	</tr>
	<tr>
		<th></th>
		<td>
			<select name="hour">
				<?php for ( $hh = 0; $hh <= 23; ++$hh ) : ?>
				<option value="<?php echo $hh; ?>" <?php selected( $ss['hour'], $hh ); ?>><?php echo $hh; ?></option>
				<?php endfor; ?>
			</select><?php _e( 'Hour' ); ?>
			<select name="min">
				<?php for ( $min = 0; $min <= 59; ++$min ) : ?>
				<option value="<?php echo $min; ?>" <?php selected( $ss['min'], $min ); ?>><?php echo $min; ?></option>
				<?php endfor; ?>
			</select><?php _e( 'Minute' ); ?>
		</td>
	</tr>

</table>
