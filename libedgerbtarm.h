/* libedgerbtarm.c
 *
 * Edge USB robotic arm, trivial control library
 *
 * Copyrigt 2010 Vincent Sanders <vince@kyllikki.org>
 *
 * Released under the MIT licence.
 */

#include <stdbool.h>

typedef enum motor_dir {
    motor_off = 0,
    motor_forward = 1,
    motor_back = 2,
    motor_brake = 3,
} motor_dir;

int edgerbtarm_init(void);
int edgerbtarm_close(void);

void edgerbtarm_stop_arm(void);
void edgerbtarm_ctrl_motor(int motorn, motor_dir direction);
void edgerbtarm_ctrl_led(bool on);
