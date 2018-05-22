#!/usr/bin/env ruby

require 'fox16'
require 'devkit'
require 'tiny_tds'

include Fox

def query_make(type,id=null)
  case type
    when 1
      result_query = "SELECT * FROM LDERC Where ID = #{id}"
    when 2
      result_query = "DECLARE @id_doc int
                      SET @id_doc = #{id}
                      DELETE FROM LDDOCOPERATION WHERE MailID in (
                      SELECT ID FROM LDMAIL WHERE ERCID = @id_doc OR BaseERCID = @id_doc)
                      DELETE FROM LDOBJECT WHERE ID IN (SELECT ID FROM LDMAIL WHERE ERCID = @id_doc OR BaseERCID = @id_doc)"
    when 3
      result_query = "DECLARE @pUID [uniqueidentifier], @pObjectTypeID INT
                      SET @pUID = 0x0C2FB3838E614B478E4F1A77B555401E --0x + UID из пакета
                      SET @pObjectTypeID = 8 --допустимо 8,19,20
                      INSERT dbo.GRK_LDEA_REJECTEDOBJECT (UID,ObjectTypeID)
                      SELECT @pUID,@pObjectTypeID
                      WHERE NOT EXISTS(SELECT NULL FROM dbo.GRK_LDEA_REJECTEDOBJECT WHERE UID = @pUID)"
  end
  return result_query
end

def checkRC(client, entry)
  result = client.execute(query_make 1,entry.text)
  return result
end

def deleteRC(client, entry)
  result = client.execute(query_make 2,entry.text)
  return result
end

def checkButtonPress
  client = client_init('dba','sql')
  #result = checkRC client, entry
  #result.each do |row|
   # puts row
  #end
  client.close
  puts "Check!!"
end



def client_init (username,password)
  client = TinyTds::Client.new username: username, password: password,
                               host: '10.47.0.117', port: 1433,
                               database: 'LDPROM', timeout: 180
  return client
end

def showPig
  @text.value = '@text.value.split.collect{|w| pig(w)}.join(" ")'
end



class MainWindows < FXMainWindow

  def initialize(app)
    # Invoke base class initialize first
    super(app, "LD3ADM Kozlovskiy EDITION", :opts => DECOR_ALL, :width => 640, :height => 480,)

    # Tooltip
    FXToolTip.new(getApp())

    # Menubar
    menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Separator
    FXHorizontalSeparator.new(self,
                              LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)

    # File Menu
    filemenu = FXMenuPane.new(self)
    FXMenuCommand.new(filemenu, "&Проверить соединение", nil, getApp(), FXApp::ID_QUIT, 0)
    FXMenuCommand.new(filemenu, "&Выход", nil, getApp(), FXApp::ID_QUIT, 0)
    FXMenuTitle.new(menubar, "&Файл", nil, filemenu)

    top = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y) do |theFrame|
      theFrame.padLeft = 10
      theFrame.padRight = 10
      theFrame.padBottom = 10
      theFrame.padTop = 10
      theFrame.vSpacing = 20
    end

    FXLabel.new(top, 'ENTER REG CARD ID OR PACKET GUID:') do |theLabel|
      theLabel.layoutHints = LAYOUT_FILL_X
    end

    p = proc { puts @text.value }

    @text = FXDataTarget.new("")

    FXTextField.new(top, 20, @text, FXDataTarget::ID_VALUE) do |theTextField|
      theTextField.layoutHints = LAYOUT_FILL_X
      theTextField.setFocus()
    end



    FXButton.new(top, 'Проверить ID',:opts => FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
                 :width => 200, :height => 50) do |checkButton|
      checkButton.connect(SEL_COMMAND) { checkButtonPress }
    end

    FXButton.new(top, 'Удалить все сообщения и отчеты',:opts => FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
        :width => 200, :height => 50) do |deleteButton|
      deleteButton.connect(SEL_COMMAND, p)
    end

    FXButton.new(top, 'Разблокировать РК', :opts => FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
                 :width => 200, :height => 50) do |unblockButton|
      unblockButton.connect(SEL_COMMAND, p)
    end

    FXButton.new(top, 'ПСО ошибка с GUID', :opts => FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
                 :width => 200, :height => 50) do |psoGuidButton|
      psoGuidButton.connect(SEL_COMMAND) { exit }
    end

  end

  # Start
  def create
    super
    show(PLACEMENT_SCREEN)
  end
end

def run
  # Make an application
  application = FXApp.new("Dialog", "FoxTest")

  # Construct the application's main window
  MainWindows.new(application)

  # Create the application
  application.create

  # Run the application
  application.run
end

run