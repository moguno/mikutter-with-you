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


workarea = get_workarea()


Plugin.create(:with_you) do
  LEFT_SIDE = 0
  RIGHT_SIDE = 1

  UserConfig[:with_you_bleft] = workarea[0]
  UserConfig[:with_you_btop] = workarea[1]
  UserConfig[:with_you_bwidth] = workarea[2]
  UserConfig[:with_you_bheight] = workarea[3]


  # 設定画面
  settings "いつでもいっしょ" do
    settings "サイドに張り付く" do
      boolean("サイドに張り付く", :with_you_side)
      select("mikutterの位置", :with_you_position, LEFT_SIDE => "左側", RIGHT_SIDE => "右側")
      adjustment("mikutterの幅", :with_you_width, 10, UserConfig[:with_you_bwidth] - UserConfig[:with_you_bleft])
    end

    boolean("ワークスペースを移動しても付いてくる", :with_you_stick)
    boolean("タスクバーに表示しない", :with_you_skip_taskbar)
  end


  # 起動時処理
  onboot do |service|
    # メインウインドウを取得
    window = Plugin.filtering(:get_windows, [])[0][0]

#    Thread.start {
#      while sleep 0.5
#        atom = Gdk::Atom.intern("_NET_ACTIVE_WINDOW",true)
#        active_xid = Gdk::Property::get(Gdk::Window.default_root_window, atom, Gdk::Atom.intern('WINDOW', true), false)[1][0]

#        if window.window.xid == active_xid
#          window.keep_below = false
#          window.keep_above = true
#        else
#          window.keep_below = true
#          window.keep_above = false
#        end
        #
#      end
#    }

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

    # サイドに張り付く
    if UserConfig[:with_you_side] == nil
      UserConfig[:with_you_side] = false
    end

    if UserConfig[:with_you_side]
      if UserConfig[:with_you_width] == nil
        UserConfig[:with_you_width] = 100
      end

      if UserConfig[:with_you_position] == nil
        UserConfig[:with_you_position] = 0
      end

      width = UserConfig[:with_you_width]

      window.decorated = false
      window.resizable = false
      window.set_size_request(width, UserConfig[:with_you_bheight])
      window.stick()
      #window.window.type_hint = Gdk::Window::TYPE_HINT_DOCK
      #window.can_focus = true

      # 左側
      if UserConfig[:with_you_position] == LEFT_SIDE
        NetWmStrutPartial::set(window.window, width, 0, 0, 0, UserConfig[:with_you_btop], UserConfig[:with_you_bheight] + UserConfig[:with_you_btop], 0, 0, 0, 0, 0, 0)
        window.move(0, UserConfig[:with_you_btop])

      # 右側
      else
        NetWmStrutPartial::set(window.window, 0, width, 0, 0, 0, 0, UserConfig[:with_you_btop], UserConfig[:with_you_bheight] - UserConfig[:with_you_btop], 0, 0, 0, 0)
        window.move(UserConfig[:with_you_bwidth] - width, UserConfig[:with_you_btop])
      end
    end
  end
end
