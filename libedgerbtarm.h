/* libedgerbtarm.c
 *
 * Edge USB robotic arm, trivial control library
 *
 * Copyrigt 2010 Vincent Sanders <vince@kyllikki.org>
 *
 * Released under the MIT licence.
 */

#include <stdbool.h>

int edgerbtarm_init(void);
int edgerbtarm_close(void);

void edgerbtarm_stop_arm(void);
void edgerbtarm_ctrl_motor(int motorn, bool on, bool fwd);
void edgerbtarm_ctrl_led(bool on);
