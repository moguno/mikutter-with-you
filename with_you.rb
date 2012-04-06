# -*- coding: utf-8 -*-
# いつでもいっしょ
# mikutterといつも一緒にいるためのプラグイン

# Ruby/Gtkにパッチが当たっているか調べる
def patched_ruby_gtk?()
  atom = Gdk::Atom.intern("_WITH_YOU_TEST", true)
  test = [1, 2, 3, 4, 5]

  Gdk::Property::change(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('CARDINAL', true) , 32, :replace, test.pack("LLLLL"))
  result = Gdk::Property::get(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('CARDINAL', true), false)[1]

  Gdk::Property::delete(Gdk::Window.default_root_window, atom)

  return test === result
end


# デスクトップの有効なサイズを得る
def get_workarea()
  atom = Gdk::Atom.intern("_NET_CURRENT_DESKTOP",true)
  desktop = Gdk::Property::get(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('CARDINAL', true), false)[1][0]

  atom = Gdk::Atom.intern("_NET_WORKAREA",true) 
  return Gdk::Property::get(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('CARDINAL', true), false)[1][desktop * 4, 4]
end


workarea = get_workarea()


Plugin.create(:with_you) do


  # 余白領域を確保する（要Ruby Gtk2にパッチ）
  def set_wm_strut_partial(window, strut)
    atom = Gdk::Atom.intern("_NET_WM_STRUT_PARTIAL", false)
    Gdk::Property::change(window, atom, Gdk::Atom.intern('CARDINAL', true) , 32, :replace, strut.pack("LLLLLLLLLLLL"))
  end


#  workarea = get_workarea()
  UserConfig[:with_you_bleft] = workarea[0]
  UserConfig[:with_you_btop] = workarea[1]
  UserConfig[:with_you_bwidth] = workarea[2]
  UserConfig[:with_you_bheight] = workarea[3]


  # 設定画面
  settings "いつでもいっしょ" do
p workarea
    if !patched_ruby_gtk?()
      settings "Ruby/Gtkにパッチが当たっていません！" do
      end
    else
      settings "側面に張り付く" do
        boolean("側面に張り付く", :with_you_side)
        select("mikutterの位置", :with_you_position, 0 => "左側", 1 => "右側")
        adjustment("mikutterの幅", :with_you_width, 10, UserConfig[:with_you_bwidth] - UserConfig[:with_you_bleft])
      end
    end

    boolean("ワークスペースを移動しても付いてくる", :with_you_stick)
    boolean("タスクバーに表示しない", :with_you_skip_taskbar)
  end


  # 起動時処理
  onboot do |service|
    # メインウインドウを取得
    window = Plugin.filtering(:get_windows, [])[0][0]

    # ワークスペースを移動しても付いてくる
    if UserConfig[:with_you_stick] == nil
      UserConfig[:with_you_stick] = false
    end

    if UserConfig[:with_you_stick]
      window.stick()
    end

    # タスクバーに表示しない
    if UserConfig[:with_you_skip_taskbar] == nil
      UserConfig[:with_you_skip_taskbar] = false
    end

    if UserConfig[:with_you_skip_taskbar]
      window.skip_taskbar_hint = true
    end

    # 側面に張り付く
    if UserConfig[:with_you_side] == nil
      UserConfig[:with_you_side] = false
    end

    if patched_ruby_gtk? && UserConfig[:with_you_side]
      if UserConfig[:with_you_width] == nil
        UserConfig[:with_you_width] = 100
      end

      if UserConfig[:with_you_position] == nil
        UserConfig[:with_you_position] = 0
      end

      width = UserConfig[:with_you_width]

      window.set_decorated(false)
      window.resizable = false
      window.set_size_request(width, UserConfig[:with_you_bheight])

      # 右側
      if UserConfig[:with_you_position] == 1
        set_wm_strut_partial(window.window, [0, width, 0, 0, 0, 0, UserConfig[:with_you_btop], UserConfig[:with_you_bheight] - UserConfig[:with_you_btop], 0, 0, 0, 0])
        window.move(UserConfig[:with_you_bwidth] - width, UserConfig[:with_you_btop])
      # 左側
      else
        set_wm_strut_partial(window.window, [width, 0, 0, 0, UserConfig[:with_you_btop], UserConfig[:with_you_bheight] + UserConfig[:with_you_btop], 0, 0, 0, 0, 0, 0])
        window.move(0, UserConfig[:with_you_btop])
      end
    end
  end
end
