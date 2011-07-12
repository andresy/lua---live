#!/usr/bin/env qlua

require 'lab'
require 'xlua'
require 'torch'
require 'random'
require 'qtwidget'

local Slides = torch.class('torch.Keynote')

function Slides:__init(slides, css, title, width, height)
   self.html = slides or error('please provide html file (slides content)')
   self.title = title or 'torch.Keynote'
   self.szw = width or 800
   self.szh = width or 600

   self.fszs = self.szh/600*14
   self.fszn = self.szh/600*18
   self.fszb = self.szh/600*28
   self.yoffset = self.szh/600*10

   self.w = qtwidget.newwindow(self.szw, self.szh, self.title)
   self.w:setstylesheet(io.open(css):read('*all'))
   self.slides = {}
   self.currentY = 3*self.fszn
   self.consoleText = ""
   self.position = 1
   self.w:gsave()

   qt.connect(self.w.listener, 'sigResize(int,int)',
              function(width, height)
                 self.w:grestore()
                 self.w:gsave()
                 self.w:scale(width/self.szw, height/self.szh)
                 self:display(self.position)
              end)

   self:fromhtml(self.html)
end

function Slides:addSlide(slide)
   table.insert(self.slides, slide)
end

function Slides:consoleClear()
   self.consoleText = ""
end

function Slides:console(text)
   text = text .. '\n'
   local w = self.w
   local options = 'TextRich|AlignTop'
   local line, height

   w:setfontsize(self.fszs)
   while true do
      w:gbegin()
      w:setcolor(0, 0.8, 0)
      w:rectangle(self.fszb, self.currentY+10, self.szw-2*self.fszb+1, self.szh-3*self.fszn-self.currentY)
      w:stroke()
      w:setcolor("#F9F7F3")
      w:rectangle(self.fszb, self.currentY+10, self.szw-2*self.fszb+1, self.szh-3*self.fszn-self.currentY)
      w:fill()

      w:setcolor(0, 0, 0)
      w:show('<pre>' .. self.consoleText .. '</pre>', self.fszb, self.currentY+10, self.szw-2*self.fszb+1, self.szh-3*self.fszn-self.currentY, options)
      w:gend()
      line, text = string.match(text, '(.-\n)(.+)')
      if not line then
         break
      end
      self.consoleText = self.consoleText .. line
      while true do
         local height = w:stringrect('<pre>' .. self.consoleText .. '</pre>', self.fszb, self.currentY+10, self.szw-2*self.fszb+1, self.szh-3*self.fszn-self.currentY, options):totable().height
         if height < self.szh-3*self.fszn-self.currentY then
            break
         end
         self.consoleText = string.match(self.consoleText, '.-\n(.+)')
      end
   end
end

function Slides:print(text, options, moveon)
   local w = self.w
   options = options or 'TextRich|AlignVCenter'
   w:setfontsize(self.fszn)
   w:setcolor(0, 0, 0)
   --   print('Y: ', self.currentY)
   w:show                (text, self.fszb, self.currentY, self.szw-2*self.fszb+1, self.szh-3*self.fszn-self.currentY, options)
   local z = w:stringrect(text, self.fszb, self.currentY, self.szw-2*self.fszb+1, self.szh-3*self.fszn-self.currentY, options)
   --   print('HEIGHT', z:totable().height, z:totable().width)
   if moveon == nil or moveon then
      self.currentY = self.currentY + z:totable().height
   end
end

function Slides.displaytimer(s,remainingmins)
   if not self.timer then
      self.timer = qt.QTimer()
      local remainingtime = (remainingmins or 20)*60
      self.timer.singleShot = false
      qt.connect(self.timer, 'timeout()',
                 function ()
                    if remainingtime > 0 then
                       remainingtime = remainingtime - 1
                    end
                    s.w:setfontsize(10)
                    local remainingSec = remainingtime % 60
                    local remainingMin = math.floor(remainingtime/60)
                    local str = 'time left: ' .. remainingMin .. ':' .. string.format("%02d", remainingSec)
                    local width = s.w:stringrect(str):totable().width
                    local height = s.w:stringrect(str):totable().height
                    s.w:setcolor(1, 1, 1)
                    s.w:rectangle(s.szw-s.fszb/2+1-width, 3*s.fszb/2+s.yoffset-3-height, width, height, 'AlignRight')
                    s.w:fill()
                    s.w:setcolor(1, 0, 0)
                    s.w:moveto(s.szw-s.fszb/2+1-width, 3*s.fszb/2+s.yoffset-3)
                    s.w:show(str)
                 end)
      self.timer:start(1000)
   end
end

function Slides:display(index)
   self.currentY = 3*self.fszn
   local w = self.w
   local slide = self.slides[index]
   w:showpage()

   w:setcolor(0, 0.2, 0.3, 0.05)
   w:rectangle(0, 0, 3*self.fszb, self.szh)
   w:fill()
   w:setcolor(0, 0.2, 0.3, 0.2)
   w:rectangle(0, 0, 3*self.fszb, self.szh)
   w:stroke()

   if slide.title then
      w:moveto(self.fszb/2, self.fszb+self.yoffset)
      w:setfontsize(self.fszb)
      if slide.color then
         w:setcolor(slide.color)
      else
         w:setcolor(0.2, 0.2, 0.2)
      end
      w:show(slide.title)

      w:setlinewidth(1)
      w:moveto(self.fszb/2, 3*self.fszb/2+self.yoffset)
      w:lineto(self.szw-self.fszb/2, 3*self.fszb/2+self.yoffset)
      w:stroke()
   end

   if slide.footleft or slide.footright then
      w:setfontsize(self.fszs)
      w:setcolor(0.3, 0.3, 0.3)
      if slide.footright then
         w:show(slide.footright, self.fszb/2, self.szh-2*self.fszn+3, self.szw-self.fszb+1, self.fszn, 'AlignRight')
      end
      if slide.footleft then
         w:show(slide.footleft, self.fszb/2, self.szh-2*self.fszn+3, self.szw-self.fszb+1, self.fszn, 'AlignLeft')
      end

      w:setlinewidth(1)
      w:setcolor(0.2, 0.2, 0.2)
      w:moveto(self.fszb/2, self.szh-2*self.fszn)
      w:lineto(self.szw-self.fszb/2, self.szh-2*self.fszn)
      w:stroke()

   end

   if slide.text then
      self:print(slide.text, slide.valign)
   end

   if slide.interaction then
      loadstring(slide.interaction)()
   end
end

function Slides:transition(index, transition)
   if not transition or not self.slides[index].transition or self.slides[index].transition == 0 then
      self:display(index)
      return
   end

   local type = self.slides[index].transition or 0
   self.fancytimer = qt.QTimer()
   qt.disconnect(self.fancytimer)
   local i = 0
   qt.connect(self.fancytimer, 'timeout()',
              function()
                 qt.qcall(qt.qApp,function()
                                     if i >= 20 then
                                        self.w:gbegin()
                                        self.fancytimer:stop()
                                        self:display(index)
                                        self.w:gend()
                                     else
                                        i = i + 1
                                        self.w:gsave()
                                        self.w:translate(self.szw/2, self.szh/2)

                                        if type == 1 then
                                           self.w:scale(1, i/20)
                                        elseif type == 2 then
                                           self.w:scale(i/20, i/20)
                                        elseif type == 3 then
                                           self.w:concat(qt.QTransform():rotated(360*i/20,'YAxis'))
                                        elseif type == 4 then
                                           self.w:translate(0, math.cos(i)*20)
                                        end
                                        self.w:translate(-self.szw/2, -self.szh/2)
                                        self.w:gbegin()
                                        self:display(index)
                                        self.w:gend()
                                        self.w:grestore()
                                        if i == 21 then
                                           self.fancytimer:stop()
                                        end
                                     end
                                  end )
              end )
   self.fancytimer:start(25)
end

function Slides:show(startindex)
   self:display(startindex or 1)

   local w = self.w
   local transition = true
   local fullScreen = false
   local step = 0
   local release = true

   qt.connect(w.listener, 'sigKeyRelease(QString,QByteArray,QByteArray)', function()
                                                                             release = true
                                                                          end)

   qt.connect(w.listener, 'sigKeyPress(QString,QByteArray,QByteArray)',
              function(bof, key, modifier)
                 if not release then return end
                 --                 print(key)
                 release = false
                 if key == 'Key_Q' then
                    os.exit()
                 end

                 if key == 'Key_F' then
                    if fullScreen then
                       fullScreen = false
                       self.w.widget:showNormal()
                    else
                       fullScreen = true
                       self.w.widget:showFullScreen()
                    end
                 end

                 if key == 'Key_B' then
                    self.position = 1
                    self:transition(self.position, transition)
                    step = 0
                 end

                 if key == "Key_Left" or key == "Key_Up" then
                    if self.position > 1 then
                       self.position = self.position - 1
                    else
                       self.position = #self.slides
                    end
                    self:transition(self.position, transition)
                    step = 0
                 end

                 if key == "Key_Right" or key == "Key_Down" then
                    if self.position < #self.slides then
                       self.position = self.position + 1
                    else
                       self.position = 1
                    end
                    self:transition(self.position, transition)
                    step = 0
                 end

                 if key == 'Key_I' and self.slides[self.position].interaction then
                    if step == 0 then
                       loadstring(self.slides[self.position].interaction)()
                    end
                    step = step + 1
                    __interaction__(self,step)
                 end

                 if key == 'Key_0' then
                    if transition == false then
                       transition = true
                    else
                       transition = false
                    end
                 end

              end, true)

   print [[
<keynote started>
  + press [->]: display next slide
  + press [<-]: display previous slide
  + press [i]: run interactive Lua code, if available
  + press [f]: goes full screen
  + press [q]: quit ]]
end

function Slides:fromhtml(htmlfile)
   local allslides = io.open(htmlfile):read('*all')
   local pagenumber = 1
   allslides:gsub('<!\-\-.-\-\->','')
   local template = '%s*<title>(.-)</title>'
   template = template .. '%s*<transition>(.-)</transition>'
   template = template .. '%s*<align>(.-)</align>'
   template = template .. '%s*(%<body%>.-%<%/body%>)'
   for title, transition, valign, txt in string.gmatch(allslides, template) do
      local align
      if valign == 'center' then
         align = 'TextRich|AlignVCenter'
      elseif valign == 'bottom' then
         align = 'TextRich|AlignBottom'
      elseif valign == 'top' then
         align = 'TextRich|AlignTop'
      end
      local interaction = string.match(txt, "<lua>(.*)</lua>")
      if interaction then
         txt = string.gsub(txt, "<lua>.*</lua>", "")
      end
      if transition == 'none' then transition = 0
      elseif transition == 'open' then transition = 1
      elseif transition == 'zoomin' then transition = 2
      elseif transition == 'flip' then transition = 3
      elseif transition == 'shake' then transition = 4
      else transition = tonumber(transition)
      end
      self:addSlide{title=title, footright=pagenumber, text=txt, interaction=interaction, valign=align, transition=transition}
      pagenumber = pagenumber + 1
   end
end

local autokeynote
for file in sys.files('.') do
   if file:find('.html') then
      local html = file
      local css = file:gsub('.html','.css')
      local title = file:gsub('.html','')
      autokeynote = torch.Keynote(html, css, title)
      autokeynote:show()
      keynote = autokeynote
      break
   end
end