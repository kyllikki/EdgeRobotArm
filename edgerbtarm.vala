/* edgerbtarm.vala
 *
 * Edge USB robotic arm user software
 *
 * Copyrigt 2010 Vincent Sanders <vince@kyllikki.org>
 *
 * Released under the MIT licence.
 */

/* compile with something like:
 * valac --pkg libedgerbtarm --vapidir . --pkg gtk+-2.0 -X -I. -X -L. -X -ledgerbtarm edgerbtarm.vala
 */

using Gtk;
using edgerbtarm;

/* This monster does the recording and playback of command lists */
public class SequencePage : VBox {

    public Label label; /* label for this page */
    private TreeView cmdlist; /* treeview for recorded list */
    private ListStore listmodel; /* data for recorded list */
    private TreeIter? lastiter = null; /* iterator pointing at last added item */
    private HButtonBox cmdctl; /* recording controls */
    private Button btn_rec;
    private Button btn_play;
    private Button btn_clear;

    private bool recording = false; /* recording in progress flag */
    private bool playback = false; /* playback in progress flag */
    TreeIter playback_iter;

    private Timer movetimer;

    public signal void movement(int motor_n, motor_dir dir);

    public void get_operation (TreeViewColumn tree_column, 
                          CellRenderer cell, 
                          TreeModel model, 
                          TreeIter iter) {

        CellRendererText cellt = (cell as CellRendererText);
        Value direction;
        Value weight;
        model.get_value(iter, 1, out direction);
        model.get_value(iter, 3, out weight);


        switch ((motor_dir)direction) {
        case motor_dir.off:
            cellt.text = "off";
            break;

        case motor_dir.forward:
            cellt.text = "forward";
            break;

        case motor_dir.back:
            cellt.text = "backward";
            break;

        case motor_dir.brake:
            cellt.text = "brake";
            break;
            
        default:
            cellt.text = "unknown";
            break;
        }

        cellt.weight = (int)weight;
    }

    private void on_time_edit (string path, string new_text) {
        Gtk.TreeIter iter;
        listmodel.get_iter_from_string (out iter, path);
        listmodel.set (iter, 2, new_text.to_double());
    }

    public SequencePage () {
        label = new Label ("Sequence 1");

        /* list data */
        listmodel = new ListStore(4, typeof (int), typeof (motor_dir), typeof (double), typeof(int));

        /* list control */    
        cmdlist = new TreeView (); 
        cmdlist.set_model (listmodel);
        cmdlist.insert_column_with_attributes (-1, "Motor", new CellRendererText (), "text", 0, "weight", 3);
        cmdlist.insert_column_with_data_func (-1, "Operation", new CellRendererText (), get_operation);
        var cellrt = new CellRendererText ();
        cellrt.edited.connect(on_time_edit);
        cmdlist.insert_column_with_attributes (-1, "Time", cellrt, "text", 2, "weight", 3, "editable", true);

        /* record button */
        btn_rec = new Button.with_label ("Record");
        btn_rec.clicked.connect(() => { if (recording) { btn_rec.label = "Record"; recording=false;} else { btn_rec.label = "Stop Recording"; recording=true; } });

        /* playback button */
        btn_play = new Button.with_label ("Play");
        btn_play.clicked.connect(() => playbk() );

        /* clear sequence */
        btn_clear = new Button.with_label ("Clear");
        btn_clear.clicked.connect(() => { listmodel.clear(); });

        var scrlwin = new Gtk.ScrolledWindow(null, null);
        scrlwin.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scrlwin.add(cmdlist);

        pack_start (scrlwin, true, true, 0);

        cmdctl = new HButtonBox();	  
        cmdctl.pack_start(btn_rec, false, false, 0);
        cmdctl.pack_start(btn_play, false, false, 0);
        cmdctl.pack_start(btn_clear, false, false, 0);

        pack_end (cmdctl, false, false, 0);


        movetimer = new Timer();
        movetimer.stop();

    }

    private bool plybk_next() {
        /* stop the current motor action */
        Value motor_n;
        Value direction;
        Value delay;
        listmodel.get_value(playback_iter, 0, out motor_n);
        listmodel.get_value(playback_iter, 1, out direction);
        listmodel.get_value(playback_iter, 2, out delay);
        movement((int)motor_n, motor_dir.brake);

        if ((playback = true) && 
            (listmodel.iter_next(ref playback_iter) == true)) {
                listmodel.get_value(playback_iter, 0, out motor_n);
                listmodel.get_value(playback_iter, 1, out direction);
                listmodel.get_value(playback_iter, 2, out delay);

                Timeout.add((int)((double)delay * 1000), plybk_next, Priority.DEFAULT);
                movement((int)motor_n, (motor_dir)direction);
                
                cmdlist.set_cursor(listmodel.get_path(playback_iter), null, false);
                
        } else {
            /* stop playback */
            playback = false;
            btn_play.label="Play";
        }
        
        return false;
    }

    private void playbk() {
        /* ensure we are not recording */
        if (recording) { 
            btn_rec.label = "Record"; 
            recording=false;
        }

        if (playback) {
            /* stop playback */
            playback = false;
            btn_play.label="Play";
        } else {
            /* start at the start */
            if (listmodel.get_iter_first(out playback_iter) == true) {
                /* start playback */


                playback = true;
                btn_play.label="Stop Playback";

                cmdlist.set_cursor(listmodel.get_path(playback_iter), null, false);

                Value motor_n;
                Value direction;
                Value delay;
                listmodel.get_value(playback_iter, 0, out motor_n);
                listmodel.get_value(playback_iter, 1, out direction);
                listmodel.get_value(playback_iter, 2, out delay);

                int msdelay;
                msdelay = (int)((double)delay * 1000);
                Timeout.add(msdelay, plybk_next, Priority.DEFAULT);
                movement((int)motor_n, (motor_dir)direction);                

            }
        }
    }


    /* linked to the buttons movement signal to track buttons */
    public void move(int motor_n, motor_dir dir) {

        if ((dir != motor_dir.forward) && 
            (dir != motor_dir.back)) {
            /* command is finished */
            if (recording) {
                if (lastiter != null) {
                    /* set movement time and remove bold */
                    listmodel.set(lastiter, 2, movetimer.elapsed(), 3, 400, -1);
                }
                TreeIter iter;
                listmodel.append (out iter);
                listmodel.set (iter, 0, motor_n, 1, dir, 2, 0.0, 3, 800, -1);
                cmdlist.scroll_to_cell(listmodel.get_path(iter), null, false, 0, 0);
                lastiter = iter;
            }
            movetimer.stop();            
        } else {
            if (recording) {
                TreeIter iter;
                listmodel.append (out iter);
                listmodel.set (iter, 0, motor_n, 1, dir, 2, 0.0,3, 800, -1);
                cmdlist.scroll_to_cell(listmodel.get_path(iter), null, false, 0, 0);
                if (lastiter != null)
                    listmodel.set(lastiter, 3, 400, -1);
                lastiter = iter;
            }
            /* start timing the command when forward or backward movement */
            movetimer.start();
        }
    }

}


public class MoveBtns : Table {

    public MoveBtns () {

        homogeneous = true;
        n_columns = 6;
        n_rows = 3;

        nmtr(0, "LED", "On", "Off", -1);
        nmtr(1, "Grip", "Close", "Open", 0);
        nmtr(2, "Wrist", "Up", "Down", 1);
        nmtr(3, "Elbow", "Fold", "Straighten", 2);
        nmtr(4, "Shoulder", "Out", "In", 3);
        nmtr(5, "Rotate", "Clockwise", "Counter", 4);
    }

    public signal void movement(int motor_n, motor_dir dir);

    private void nmtr(int x, string lbl, string fwdlbl, string bklbl, int motrn) {
        var col_label = new Label (lbl);
        var col_fwd = new Button.with_label (fwdlbl);
        var col_bk = new Button.with_label (bklbl);

        col_fwd.pressed.connect (() => movement(motrn, motor_dir.forward));
        col_fwd.released.connect (() => movement(motrn, motor_dir.brake));
        col_bk.pressed.connect (() => movement(motrn, motor_dir.back));
        col_bk.released.connect (() => movement(motrn, motor_dir.brake));

        attach_defaults(col_label, x, x+1, 0,1);
        attach_defaults(col_fwd, x, x+1, 1,2);
        attach_defaults(col_bk, x, x+1, 2,3);

    }

}

public class USBArm {

    private bool inited = false;

    public USBArm () {
        if (edgerbtarm.init() == 0)
            inited = true;
        else
            stderr.printf("Unable to connect to USB device\n");
    }

    ~USBArm () {
        if (inited == true)
            edgerbtarm.close();
    }

    public void move (int motor_n, motor_dir dir) {
        if (inited == true)
            edgerbtarm.ctrl_motor(motor_n, dir);
    }

}

int main (string[] args) {

    Gtk.init (ref args);

    var usbarm = new USBArm();

    var window = new Window (WindowType.TOPLEVEL);
    window.title = "Edge USB attached Robot Arm";
    window.set_default_size (300, 100);
    window.position = WindowPosition.CENTER;
    window.destroy.connect (Gtk.main_quit);

    var armimage= new Image.from_file("edgerbtarm.png");

    var tbl = new MoveBtns ();
    tbl.movement.connect((motor_n, dir) => usbarm.move(motor_n, dir));

    var sequencepage = new SequencePage ();
    sequencepage.movement.connect((motor_n, dir) => usbarm.move(motor_n, dir));
    tbl.movement.connect((motor_n, dir) => sequencepage.move(motor_n, dir));

    var sequencebook = new Notebook();
    sequencebook.append_page(sequencepage, sequencepage.label);

    var vbox = new VBox (false, 0);
    vbox.pack_start (armimage, false, false, 0);
    vbox.pack_start (tbl, false, false, 0);
    vbox.pack_end (sequencebook, true, true, 0);

    window.add (vbox);

    window.show_all ();

    Gtk.main ();


    return 0;
}

