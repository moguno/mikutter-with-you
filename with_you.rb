# -*- coding: utf-8 -*-
# いつでもいっしょ
# mikutterといつも一緒にいるためのプラグイン

require 'netwmstrutpartial'

# デスクトップの有効なサイズを得る
def get_workarea()
  atom = Gdk::Atom.intern("_NET_CURRENT_DESKTOP",true)
  desktop = Gdk::Property::get(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('CARDINAL', true), false)[1][0]

  atom = Gdk::Atom.intern("_NET_WORKAREA",true) 
  return Gdk::Property::get(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('CARDINAL', true), false)[1][desktop * 4, 4]
end



class ::Gtk::MikutterWindow
  alias :initialize_homo :initialize
  
  def initialize(imaginally, *args)
    initialize_homo(imaginally, *args)
    
    def @panes.window=(win)
      @window = win
    end
    
    @panes.window = self

    @panes.instance_eval {
      alias :remove_homo :remove
      
      def with_you(window, position, width, height)
        Plugin.create(:with_you).with_you(window, position, width, height)
      end

      def remove(widget)
        result = remove_homo(widget)
        with_you(@window, 
                 UserConfig[:with_you_position], 
                 children.size * UserConfig[:with_you_width],
                 UserConfig[:with_you_height])
        result
      end

      alias :pack_start_homo :pack_start

      def pack_start(child, expand = true, fill = true, padding = 0)
        result = pack_start_homo(child, expand, fill, padding)
        with_you(@window, 
                 UserConfig[:with_you_position], 
                 children.size * UserConfig[:with_you_width], 
                 UserConfig[:with_you_height])
        result
      end

      alias :pack_end_homo :pack_end

      def pack_end(child, expand = true, fill = true, padding = 0)
        result = pack_end_homo(child, expand, fill, padding)
        with_you(@window, 
                 UserConfig[:with_you_position], 
                 children.size * UserConfig[:with_you_width],
                 UserConfig[:with_you_height])

        result
      end
    }

   end
end

Plugin.create(:with_you) do
  LEFT_SIDE = 0
  RIGHT_SIDE = 1

  WORK_AREA = get_workarea()

  # コンフィグの初期化
  def initialize_config
    if UserConfig[:with_you_width] == nil
      UserConfig[:with_you_width] = 100
    end

    if UserConfig[:with_you_position] == nil
      UserConfig[:with_you_position] = 0
    end

    if UserConfig[:with_you_height] == nil
      UserConfig[:with_you_height] = WORK_AREA[3]
    end
  end

  # Change window position, and sticky status.
  def with_you(window, position, width, height)

    initialize_config
    width = UserConfig[:with_you_width] unless width
    position = UserConfig[:with_you_position] unless position
    height = UserConfig[:with_you_height] unless height

    if UserConfig[:with_you_stick]
      window.stick(); end

    if UserConfig[:with_you_skip_taskbar]
      window.skip_taskbar_hint = true; end

    if UserConfig[:with_you_side] then
      notice "[with_you] Dock mode:config=#{UserConfig[:with_you_side]}"
      window.resizable = false
      window.set_default_size(width, height)
      window.set_size_request(width, height)
      window.gravity = Gdk::Window::GRAVITY_STATIC
      win_top = 0
      win_left = 0
      if position == LEFT_SIDE
        win_left = WORK_AREA[0]
        win_top = WORK_AREA[1]
      else
        win_left = WORK_AREA[0] + WORK_AREA[2] - width
        win_top = WORK_AREA[1]; end
      
      window.window.type_hint = Gdk::Window::TYPE_HINT_DOCK
      window.can_focus = true
      window.accept_focus = true
      window.move(win_left , win_top)

      # 左側
      if position == LEFT_SIDE
        NetWmStrutPartial::set(window.window, win_left + width, 0, 0, 0, win_top, win_top + height, 0, 0,
                               0, 0, 0, 0)
      # 右側
      else
        NetWmStrutPartial::set(window.window, 0, width, 0, 0, 0, 0, win_top, win_top + height,
                               0, 0, 0, 0); end

    else
      notice "[with_you] NORMAL window mode:config=#{UserConfig[:with_you_side]}"
      NetWmStrutPartial::set(window.window, 0, 0, 0, 0, 0, 0, 0, 0,
                             0, 0, 0, 0)
      window.resizable = true
      window.window.type_hint = Gdk::Window::TYPE_HINT_NORMAL
      window.decorated = true
      window.set_default_size(0, 0)
    end
  end

  # DOCKの時に強制的にフォーカスを奪い取る
  def force_set_focus(toplevel, widget, recursive=true)
    begin
      widget.signal_connect("clicked") {|window, event|
        notice "CLICKED:TopLevel#present (win=#{window})"
        toplevel.present
      }
    rescue GLib::NoSignalError => e
    end
    begin
       widget.signal_connect("button-press-event") {|window, event|
        notice "BUTTON-PRESS:TopLevel#present (win=#{window})"
        toplevel.present
        false
      }
    rescue GLib::NoSignalError =>e
    end
    begin
       widget.signal_connect("button-release-event") {|window, event|
        notice "BUTTON-RELEASE:TopLevel#present (win=#{window})"
        toplevel.present
        false
      }
    rescue GLib::NoSignalError =>e
    end
    if recursive && widget.is_a?(Gtk::Container) then
      widget.children.each {|c|
        force_set_focus(toplevel, c)
        false
      }
    end
  end

  # 設定画面
  settings "いつでもいっしょ" do
    settings "サイドに張り付く" do
      boolean("サイドに張り付く", :with_you_side)
      select("mikutterの位置", :with_you_position, LEFT_SIDE => "左側", RIGHT_SIDE => "右側")
      adjustment("mikutterの幅", :with_you_width, 10, WORK_AREA[2])
      adjustment("mikutterの高さ", :with_you_height, 10, WORK_AREA[3])
    end

    boolean("ワークスペースを移動しても付いてくる", :with_you_stick)
    boolean("タスクバーに表示しない", :with_you_skip_taskbar)
  end

  command(:close_window,
          name: 'ウインドウを閉じる',
          condition: lambda{ |opt| true },
          visible: true,
          icon: "#{File.dirname(__FILE__)}/action_delete.png",
          role: :window) do |opt| Gtk.main_quit end

  # 起動時処理(for 0.1)
  onboot do |service|
    # メインウインドウを取得
    window_tmp = Plugin.filtering(:get_windows, [])

    if (window_tmp == nil) || (window_tmp[0][0] == nil) then
      next
    end

    window = window_tmp[0][0]
    with_you(window, 
             UserConfig[:with_you_position],
             window.children.size * UserConfig[:with_you_width],
             UserConfig[:with_you_height])
  end


  # 起動時処理(for 0.2)
  on_window_created do |i_window|
    # メインウインドウを取得
    window_tmp = Plugin.filtering(:gui_get_gtk_widget,i_window)

    if (window_tmp == nil) || (window_tmp[0] == nil) then
      next
    end

    window = window_tmp[0]

    with_you(window, 
             UserConfig[:with_you_position],
             UserConfig[:with_you_width],
             UserConfig[:with_you_height])
    UserConfig.connect(:with_you_position) {|key, val, before_val,id|
      with_you(window, 
               val, 
               window.children.size * UserConfig[:with_you_width],
                UserConfig[:with_you_height])
    }
    UserConfig.connect(:with_you_width) {|key, val, before_val,id|
      with_you(window, 
               UserConfig[:with_you_position], 
               window.children.size * val, 
               UserConfig[:with_you_height])
    }
    UserConfig.connect(:with_you_height) {|key, val, before_val,id|
      with_you(window, 
               UserConfig[:with_you_position],
               window.children.size * UserConfig[:with_you_width],
               val)
    }
    
    force_set_focus(window, window, false)
  end
  
  def set_focus_callback(extractor)
    return Proc.new { |i_widget, i_parent|
    i_window = i_widget.ancestor_of(Plugin::GUI::Window)
    widget_tmp = Plugin.filtering(:gui_get_gtk_widget, i_widget)
    if (widget_tmp == nil) || (widget_tmp[0] == nil) then
      next
    end
    window_tmp = Plugin.filtering(:gui_get_gtk_widget, i_window)
    if (window_tmp == nil) || (window_tmp[0] == nil) then
      next
    end
    widget = widget_tmp[0]
    window = window_tmp[0]
    force_set_focus(window, extractor.call(widget), false)
    }
  end
  
  on_gui_timeline_join_tab(&set_focus_callback(lambda {|w| w}))
  on_gui_postbox_join_widget(&set_focus_callback(lambda {|w| w.post}))
  
end
