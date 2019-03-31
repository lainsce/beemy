/*
* Copyright (c) 2018 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Beemy {
    public class MainWindow : Gtk.ApplicationWindow {
        //calc page widgets
        public Gtk.Label label_beemy;
        public Gtk.Label label_beemy_info;
        public Gtk.ComboBoxText base_weight_cb;
        public Gtk.ComboBoxText base_height_cb;
        public Gtk.EntryBuffer entry_weight_buffer;
        public Gtk.EntryBuffer entry_height_buffer;

        //results page widgets
        public Gtk.Label label_result;
        public Gtk.Label label_result_info;
        public Gtk.Label label_result_grade;
        public Gtk.Label label_result_grade_number;
        public Gtk.Button return_button;
        public Gtk.Button color_button_action;

        public Gtk.Stack stack;

        public string grade_type = "None";
        public double res = 0.00;
        public double weight_entry_text = 0.00;
        public double height_entry_text = 0.00;

        public double[] weight_conv = {1, 0.45359237};
        public double[] height_conv = {1, 0.01, 0.3048};

        public string[] weight_units = {"kg", "lbs"};
        public string[] height_units = {"m", "cm", "ft"};

        public MainWindow (Gtk.Application application) {
            GLib.Object (application: application,
                 icon_name: "com.github.lainsce.beemy",
                 resizable: false,
                 title: "",
                 height_request: 450,
                 width_request: 450,
                 border_width: 6
            );
        }

        construct {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/beemy/stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            // Main page
            create_titlebar ();
            create_calc_page ();

            read_settings ();

            create_help ();
            create_action_button ();
            attach_grid ();

            // Results page
            create_results_labels ();
            body_mass_index_res ();
            body_mass_index_grade ();

            create_results_help ();
            attach_results_grid ();
            create_stack ();

            // Finish
            add_buttons_callbacks ();
            decorate ();
        }

        public override bool delete_event (Gdk.EventAny event) {
            int x, y;
            get_position (out x, out y);

            var settings = AppSettings.get_default ();
            settings.window_x = x;
            settings.window_y = y;
            settings.weight_type = base_weight_cb.get_active();
            settings.height_type = base_height_cb.get_active();

            return false;
        }

        public void show_return (bool v) {
            return_button.set_visible (v);
        }

        public void sensive_color_button (bool v) {
            color_button_action.set_sensitive (v);
        }

        public double body_mass_index_res () {
            var weight = weight_entry_text * weight_conv[base_weight_cb.active];
            var height = height_entry_text * height_conv[base_height_cb.active];

            res = weight / (height * height);

            var number_context = label_result_grade_number.get_style_context ();
            if (res < 18.7) {
                number_context.add_class ("underweight-label");
                number_context.remove_class ("healthy-label");
                number_context.remove_class ("obese-label");
                number_context.remove_class ("overweight-label");
            } else if (18.8 <= res <= 24.0) {
                number_context.add_class ("healthy-label");
                number_context.remove_class ("underweight-label");
                number_context.remove_class ("obese-label");
                number_context.remove_class ("overweight-label");
            } else if (24.1 <= res <= 30.0) {
                number_context.add_class ("overweight-label");
                number_context.remove_class ("underweight-label");
                number_context.remove_class ("healthy-label");
                number_context.remove_class ("obese-label");
            } else if (res > 30.1) {
                number_context.add_class ("obese-label");
                number_context.remove_class ("healthy-label");
                number_context.remove_class ("underweight-label");
                number_context.remove_class ("overweight-label");
            }

            label_result_grade.set_markup ("\n" + _("Your Body Mass Index is:")+ "\n");
            label_result_grade_number.set_markup ("%.2f".printf(res));
            return res;
        }

        public string body_mass_index_grade () {
            if (res < 18.7) {
                grade_type = _("Underweight");
            } else if (18.8 <= res <= 24.0) {
                grade_type = _("Healthy");
            } else if (24.1 <= res <= 30.0) {
                grade_type = _("Overweight");
            } else if (res > 30.1) {
                grade_type = _("Obese");
            }

            label_result_info.set_markup (_("You are considered") + (" <span font=\"16\">%s</span>").printf(grade_type) + "\n" + _("in the official Body Mass Index chart."));

            return grade_type;
        }

        public Gtk.ComboBoxText createComboBox (string[] elements, int margin) {
            var cb = new Gtk.ComboBoxText();
            cb.margin = margin;
            foreach (string e in elements)
                cb.append_text(e);
            return cb;
        }
        private Gtk.HeaderBar titlebar;
        private Gtk.Button help_button;

        public void create_titlebar () {
            titlebar = new Gtk.HeaderBar ();
            titlebar.has_subtitle = false;
            titlebar.show_close_button = true;

            var titlebar_style_context = titlebar.get_style_context ();
            titlebar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            titlebar_style_context.add_class ("default-decoration");
            titlebar_style_context.add_class ("beemy-toolbar");

            help_button = new Gtk.Button ();
            help_button.set_image (new Gtk.Image.from_icon_name ("help-contents-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            help_button.set_always_show_image (true);
            help_button.vexpand = false;
            help_button.tooltip_text = _("Learn about Body Mass Index");

            return_button = new Gtk.Button.with_label (_("Calculate"));
            return_button.vexpand = false;
            return_button.valign = Gtk.Align.CENTER;
            return_button.get_style_context ().add_class ("back-button");

            help_button.clicked.connect (() => {
                Granite.Services.System.open_uri(_("https://en.wikipedia.org/wiki/Body_mass_index"));
            });

            titlebar.pack_end (help_button);
            titlebar.pack_start (return_button);
        }

        private Gtk.Entry entry_height;
        private Gtk.Entry entry_weight;

        public void create_calc_page () {
            label_beemy = new Gtk.Label (_("Beemy"));
            label_beemy.set_halign (Gtk.Align.CENTER);
            label_beemy.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
            label_beemy.hexpand = true;
            label_beemy.margin_bottom = 6;

            label_beemy_info = new Gtk.Label (_("Calculate your Body Mass Index:"));
            label_beemy_info.set_halign (Gtk.Align.CENTER);
            label_beemy_info.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            label_beemy_info.hexpand = true;
            label_beemy_info.margin_bottom = 6;

            entry_weight_buffer = new Gtk.EntryBuffer ();
            entry_weight = new Gtk.Entry.with_buffer (entry_weight_buffer);
            entry_weight.vexpand = false;
            entry_weight.hexpand = true;
            entry_weight.has_focus = false;
            entry_weight.margin_top = 5;
            entry_weight.margin_bottom = 5;
            entry_weight.placeholder_text = _("Enter weight…");
            entry_weight.icon_press.connect ((pos, event) => {
                if (pos == Gtk.EntryIconPosition.SECONDARY) {
                    entry_weight.set_text ("");
                }
            });

            entry_weight.changed.connect (() => {
                if (entry_weight.text.length > 0) {
                    entry_weight.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
                    sensive_color_button (true);
                } else {
                    entry_weight.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                }
            });

            entry_weight_buffer.inserted_text.connect (() => {
                weight_entry_text = double.parse(entry_weight.get_text ());
            });

            entry_height_buffer = new Gtk.EntryBuffer ();
            entry_height = new Gtk.Entry.with_buffer (entry_height_buffer);
            entry_height.vexpand = false;
            entry_height.hexpand = true;
            entry_height.has_focus = false;
            entry_height.margin_top = 5;
            entry_height.margin_bottom = 5;
            entry_height.placeholder_text = _("Enter height…");

            entry_height.icon_press.connect ((pos, event) => {
                if (pos == Gtk.EntryIconPosition.SECONDARY) {
                    entry_height.set_text ("");
                }
            });

            entry_height.changed.connect (() => {
                if (entry_height.text.length > 0) {
                    entry_height.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
                    sensive_color_button (true);
                } else {
                    entry_height.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                }
            });

            entry_height_buffer.inserted_text.connect (() => {
                height_entry_text = double.parse(entry_height.get_text ());
            });
            base_height_cb = createComboBox(height_units, 6);
            base_weight_cb = createComboBox(weight_units, 6);
        }

        public void read_settings () {
            var settings = AppSettings.get_default ();
            if (settings.weight_type < 0 || settings.weight_type > 1)
                settings.weight_type = 0;
            if (settings.height_type < 0 || settings.height_type > 2)
                settings.height_type = 0;

            base_weight_cb.set_active(settings.weight_type);
            base_height_cb.set_active(settings.height_type);

            int x = settings.window_x;
            int y = settings.window_y;
            int weight_type = base_weight_cb.get_active();
            weight_type = settings.weight_type;
            int height_type = base_height_cb.get_active();
            height_type = settings.height_type;

            if (x != -1 && y != -1) {
                move (x, y);
            }
        }

        private Gtk.Image weight_help;
        private Gtk.Image height_help;

        public void create_help () {
            weight_help = create_help_image(_("You can choose your preferred weight unit."));
            height_help = create_help_image(_("You can choose your preferred height unit."));
        }

        public Gtk.Image create_help_image (string message) {
            var res = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
            res.halign = Gtk.Align.START;
            res.hexpand = true;
            res.tooltip_text = _(message);
            return res;
        }

        public void create_action_button () {
            color_button_action = new Gtk.Button ();
            color_button_action.has_focus = false;
            color_button_action.halign = Gtk.Align.CENTER;
            color_button_action.margin = 12;
            color_button_action.height_request = 48;
            color_button_action.width_request = 48;
            color_button_action.set_image (new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            color_button_action.set_always_show_image (true);
            color_button_action.tooltip_text = _("Calculate!");
            var color_button_action_context = color_button_action.get_style_context ();
            color_button_action_context.add_class ("color-button");
            color_button_action_context.add_class ("color-button-action");
            sensive_color_button (false);
        }

        private Gtk.Grid home_grid;

        public void attach_grid () {
            home_grid = new Gtk.Grid ();
            home_grid.margin_top = 0;
            home_grid.column_spacing = 6;
            home_grid.row_spacing = 6;
            home_grid.attach (label_beemy, 0, 0, 3, 1);
            home_grid.attach (label_beemy_info, 0, 1, 3, 1);
            home_grid.attach (entry_weight, 0, 2, 1, 1);
            home_grid.attach (entry_height, 0, 3, 1, 1);
            home_grid.attach (base_weight_cb, 1, 2, 1, 1);
            home_grid.attach (base_height_cb, 1, 3, 1, 1);
            home_grid.attach (weight_help, 2, 2, 1, 1);
            home_grid.attach (height_help, 2, 3, 1, 1);
            home_grid.attach (color_button_action, 0, 4, 3, 1);
        }

        public void create_results_labels () {
            label_result = new Gtk.Label (_("Your Results:"));
            label_result.set_halign (Gtk.Align.START);
            label_result.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
            label_result.hexpand = true;
            label_result.margin_bottom = 6;

            label_result_info = new Gtk.Label ("");
            label_result_info.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            label_result_info.halign = Gtk.Align.CENTER;
            label_result_info.hexpand = true;
            label_result_info.margin_bottom = 6;

            label_result_grade = new Gtk.Label ("");
            label_result_grade.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            label_result_grade.halign = Gtk.Align.CENTER;
            label_result_grade.hexpand = true;

            label_result_grade_number = new Gtk.Label ("");
            label_result_grade_number.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
            label_result_grade_number.halign = Gtk.Align.CENTER;
            label_result_grade_number.hexpand = true;
        }

        private Gtk.Image bmi_help;

        public void create_results_help () {
            bmi_help = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
            bmi_help.halign = Gtk.Align.START;
            bmi_help.hexpand = true;
            bmi_help.margin_top = 3;
            bmi_help.valign = Gtk.Align.CENTER;
            bmi_help.hexpand = true;
            bmi_help.tooltip_text = _("The Body Mass Index does not tell % of muscular mass or fat mass, all it does is a fast checkup on your health.");
        }

        private Gtk.Grid results_grid;

        public void attach_results_grid () {
            results_grid = new Gtk.Grid ();
            results_grid.margin_top = 0;
            results_grid.column_spacing = 6;
            results_grid.row_spacing = 6;
            results_grid.attach (label_result, 0, 0, 3, 1);
            results_grid.attach (label_result_info, 0, 1, 3, 1);
            results_grid.attach (label_result_grade, 0, 2, 3, 1);
            results_grid.attach (label_result_grade_number, 0, 3, 3, 1);
            results_grid.attach (bmi_help, 2, 3, 3, 1);
        }

        public void create_stack () {
            stack = new Gtk.Stack ();
            stack.margin = 6;
            stack.margin_top = 0;
            stack.homogeneous = true;
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (home_grid);
            stack.add (results_grid);
            stack.set_visible_child (home_grid);
        }

        public void add_buttons_callbacks () {
            return_button.clicked.connect (() => {
                stack.set_visible_child (home_grid);
                show_return (false);
            });

            color_button_action.clicked.connect (() => {
                stack.set_visible_child (results_grid);
                show_return (true);
                body_mass_index_res ();
                body_mass_index_grade ();
            });

            button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_PRIMARY) {
                    begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                    return true;
                }
                return false;
            });
        }


        public void decorate () {
            this.add (stack);
            stack.show_all ();
            this.set_titlebar (titlebar);
            this.get_style_context ().add_class ("rounded");
        }
    }
}
