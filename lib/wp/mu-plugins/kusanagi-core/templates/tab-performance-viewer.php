<?php if ( ! defined( 'ABSPATH' ) )  exit; ?>
<?php $caps = get_role( 'administrator' ); $s = $this->modules[$_GET['tab']]->settings; ?>
			<h3><?php _e( 'Performance Viewer', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
			<tr>
				<th><?php _e( 'Display performance on admin-bar.', 'wp-kusanagi' ); ?></th>
				<td>
					<input type="hidden" name="kusanagi-performance-viewer[enable]" value="0">
					<label for="performace-viewer-enable">
						<input type="checkbox" name="kusanagi-performance-viewer[enable]" id="performace-viewer-enable" value="1"<?php echo $s['enable'] ? ' checked="checked"' : ''; ?>>
						<?php _e( 'Enable', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Requierd capability to display performance', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="kusanagi-performance-viewer[capability]">
<?php foreach ( $caps->capabilities as $cap => $has ) : ?>
						<option value="<?php echo esc_attr( $cap ); ?>"<?php echo $cap == $s['capability'] ? ' selected="selected"' : ''; ?>><?php echo esc_html( $cap ); ?></option>
<?php endforeach; ?>
					</select>
				</td>
			</tr>
			</table>
