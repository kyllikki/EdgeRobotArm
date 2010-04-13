using Gtk;
using edgerbtarm;


public class CmdPage : VBox {

    public Label label;
    private TreeView cmdlist;
    private ListStore listmodel;
    private TreeIter? lastiter = null;

    private HBox cmdctl; /* controls */
    private Button btn_rec;
    private Button btn_play;
    private Button btn_clear;

    private bool recording = false;
    private bool playback = false;
    TreeIter playback_iter = {};


    private Timer movetimer;

    public CmdPage (MoveBtns btns) {
        label = new Label ("List1");

        /* list data */
        listmodel = new ListStore(4, typeof (int), typeof (bool), typeof (double), typeof(int));

        /* list control */    
        cmdlist = new TreeView (); 
        cmdlist.set_model (listmodel);
        cmdlist.insert_column_with_attributes (-1, "Motor", new CellRendererText (), "text", 0, "weight", 3);
        cmdlist.insert_column_with_attributes (-1, "Operation", new CellRendererText (), "text", 1, "weight", 3);
        cmdlist.insert_column_with_attributes (-1, "Time", new CellRendererText (), "text", 2, "weight", 3);

        /* list controls */
        btn_rec = new Button.with_label ("Record");
        btn_rec.clicked.connect(() => { if (recording) { btn_rec.label = "Record"; recording=false;} else { btn_rec.label = "Stop Recording"; recording=true; } });

        btn_play = new Button.with_label ("Play");
        btn_play.clicked.connect(() => playbk() );
        btn_clear = new Button.with_label ("Clear");
        btn_clear.clicked.connect(() => { listmodel.clear(); });

        var scrlwin = new Gtk.ScrolledWindow(null, null);
        scrlwin.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scrlwin.add(cmdlist);

        pack_start (scrlwin, true, true, 0);

        cmdctl = new HBox(true, 0);	  
        cmdctl.pack_start(btn_rec, false, false, 0);
        cmdctl.pack_start(btn_play, false, false, 0);
        cmdctl.pack_start(btn_clear, false, false, 0);

        pack_end (cmdctl, false, false, 0);

        btns.movement.connect((motor_n, on, dir) => mtrmove(motor_n, on, dir));

        movetimer = new Timer();
        movetimer.stop();

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
            /* start playback */
            playback = true;
            btn_play.label="Stop Playback";
            listmodel.get_iter_first(out playback_iter); /* start at the start */

            cmdlist.scroll_to_cell(listmodel.get_path(playback_iter), null, false, 0, 0);

            Value motor_n;
            Value direction;
            Value delay;
            listmodel.get_value(playback_iter, 0, out motor_n);
            listmodel.get_value(playback_iter, 0, out direction);
            listmodel.get_value(playback_iter, 0, out delay);

        }
    }

    private void mtrmove(int motor_n, bool on, bool dir) {
        if (on) {
            movetimer.start();
        } else {
            if (recording) {
                TreeIter iter;
                listmodel.append (out iter);
                listmodel.set (iter, 0, motor_n, 1, dir, 2, movetimer.elapsed(), 3, 800, -1);
                cmdlist.scroll_to_cell(listmodel.get_path(iter), null, false, 0, 0);
                if (lastiter != null)
                    listmodel.set(lastiter, 3, 400, -1);
                lastiter = iter;
            }
            movetimer.stop();            
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
        nmtr(5, "Rotate", "Clockwise", "Counterclockwise", 4);
    }

    public signal void movement(int motor_n, bool on, bool dir);

    private void nmtr(int x, string lbl, string fwdlbl, string bklbl, int motrn) {
        var col_label = new Label (lbl);
        var col_fwd = new Button.with_label (fwdlbl);
        var col_bk = new Button.with_label (bklbl);

        col_fwd.pressed.connect (() => movement(motrn, true, true));
        col_fwd.released.connect (() => movement(motrn, false, true));
        col_bk.pressed.connect (() => movement(motrn, true, false));
        col_bk.released.connect (() => movement(motrn, false, false));

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

    public void move (int motor_n, bool on, bool dir) {
        if (inited == true)
            edgerbtarm.ctrl_motor(motor_n, on, dir);
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


    var tbl = new MoveBtns ();
    tbl.movement.connect((motor_n, on, dir) => usbarm.move(motor_n, on, dir));

    var cmdpage = new CmdPage (tbl);

    var notebk = new Notebook();
    notebk.append_page(cmdpage, cmdpage.label);

    var vbox = new VBox (false, 0);
    vbox.pack_start (tbl, false, false, 0);
    vbox.pack_end (notebk, true, true, 0);

    window.add (vbox);

    window.show_all ();

    Gtk.main ();


    return 0;
}

