<?php if ( ! defined( 'ABSPATH' ) ) exit; ?>
 <?php $s = $this->modules[$_GET['tab']]->settings; ?>
			<h3><?php _e( 'Image Optimizer', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
				<tr>
					<th><?php _e( 'Enable Image Optimize', 'wp-kusanagi' ); ?></th>
					<td>
						<input type="hidden" name="enable_image_optimize" value="0">
						<label for="enable_image_optimize">
							<input type="checkbox" id="enable_image_optimize" name="enable_image_optimize" value="1"<?php echo 1 == $s['enable_image_optimize'] ? ' checked="checked"' : ''; ?>>
							<?php _e( 'Enable', 'wp-kusanagi' ); ?>
						</label>
					</td>
				</tr>
				<tr>
					<th><?php _e( 'Jpeg quality', 'wp-kusanagi' ); ?></th>
					<td><div id="jpeg_quality_slider"><span id="quality-value"><?php echo esc_html( $s['jpeg_quality'] ); ?></span></div>
					<input type="hidden" id="jpeg_quality" name="jpeg_quality" value="<?php echo esc_attr( $s['jpeg_quality'] ); ?>">
					</td>
				</tr>
				<tr>
					<th><?php _e( 'Max full image widh', 'wp-kusanagi' ); ?></th>
					<td><input type="number" name="max_image_width" value="<?php echo esc_attr( $s['max_image_width'] ); ?>"> px
					<br><?php _e( '* larger than 320px', 'wp-kusanagi' ); ?>
					</td>
				</tr>
			</table>
