local cp={}

function math.getDistance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^0.5
end

function math.axisRot(x,y,rot)
    local xx=math.cos(rot)*x-math.sin(rot)*y
    local yy=math.cos(rot)*y+math.sin(rot)*x
    return xx,yy
end

function math.sign(x)
    if x>0 then return 1
    elseif x<0 then return -1
    else return 0 end
end

function math.getRot(x1,y1,x2,y2,toggle)
    if x1==x2 and y1==y2 then return 0 end
    local angle=math.atan((x1-x2)/(y1-y2))
    if y1-y2<0 then angle=angle-math.pi end
    if toggle==true then angle=angle+math.pi end
    if angle>0 then angle=angle-2*math.pi end
    if angle==0 then return 0 end
    return -angle
end

function cp:RGBtoHSV(r,g,b)
    local max=math.max(r,g,b)
    local min=math.min(r,g,b)
    local d=max-min
    local v=max
    local s
    if v==0 then
        s=0
    else
        s=1-min/max
    end
    local h=0
    if d~=0 then
        if r==max then
            h=(g-b)/d
        elseif g==max then
            h=2+(b-r)/d
        elseif b==max then
            h=4+(r-g)/d
        end
        h=h*60
        if h<0 then h=h+360 end
    end

    return h,s,v
end

function cp:HSVtoRGB(h,s,v)
    local r,g,b
    local x,y,z
    if s==0 then
        r=v;g=v;b=v
    else
        h=h/60
        i=math.floor(h)
        f=h-i
        x=v*(1-s)
        y=v*(1-s*f)
        z=v*(1-s*(1-f))
    end
    if i==0 then
        r=v;g=z;b=x
    elseif i==1 then
        r=y;g=v;b=x
    elseif i==2 then
        r=x;g=v;b=z
    elseif i==3 then
        r=x;g=y;b=v
    elseif i==4 then
        r=z;g=x;b=v
    elseif i==5 then
        r=v;g=x;b=y
    else
        r=v;g=z;b=x
    end
    return r / 255,g / 255,b / 255
end

function cp:create(x,y,size)
    local lenIn,lenOut=0.75*size,size
    self.size=size
    self.cx=x+size
    self.cy=y+size
    self.x=x
    self.y=y
    self.canvas = love.graphics.newCanvas(size*2,size*2)
    self.canvas2 = love.graphics.newCanvas(size*2,size*2)
    self.canvas:renderTo(
        function()
            love.graphics.setLineWidth(2)
            for h=1,360 do
                local r,g,b=self:HSVtoRGB(h,1,255)
                love.graphics.setColor(r, g, b, 1)
                local x1,y1=math.axisRot(0,lenOut,math.rad(h))
                local x2,y2=math.axisRot(0,lenIn,math.rad(h))
                love.graphics.line(x1+size, y1+size, x2+size, y2+size)
            end
        end
    )
    self.ringDeg=0
    self.hx,self.hy=self.cx,self.cy+(lenIn+lenOut)/2
    self.sx,self.sy=self.cx,self.cy+lenIn
    self.sc={255,0,0}
    cp:tri()
end

function cp:tri()
    local lenIn=self.size*0.75
    local x1,y1=math.axisRot(0,lenIn,math.rad(self.ringDeg))
    local x2,y2=math.axisRot(0,lenIn,math.rad(self.ringDeg+120))
    local x3,y3=math.axisRot(0,lenIn,math.rad(self.ringDeg+240))
    local ver={
        {
            x1, y1,
            0, 0,
            self:HSVtoRGB(self.ringDeg,1,255)
        },
        {
            x2, y2,
            0, 0,
            255,255,255
        },
        {
            x3, y3,
            0, 0,
            0,0,0
        },
    }
    local mesh = love.graphics.newMesh(ver, "fan")
    self.canvas2:renderTo(
        function()
            love.graphics.clear()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(mesh, self.size,self.size)
        end
    )
end

function cp:getColor(obj,x,y)
    return obj:newImageData():getPixel( x-self.x, y-self.y ) --r,g,b,a
end

function cp:update()
    if  love.mouse.isDown(1) then
        local x, y = love.mouse.getPosition()
        local len = math.getDistance(x,y,self.cx,self.cy)
        if len>=0.75*self.size and len<=self.size then
            self.ringDeg=math.deg(math.getRot(x,y,self.cx,self.cy))
            self.hx=x
            self.hy=y
            self.sx,self.sy=math.axisRot(0,0.75*self.size,math.rad(self.ringDeg))
            self.sx=self.sx+self.x+self.size
            self.sy=self.sy+self.y+self.size
            local r,g,b=self:HSVtoRGB(self.ringDeg,1,255)
            self.sc={r,g,b}
        elseif len<0.75*self.size then
            local r,g,b,a=self:getColor(self.canvas2,x,y)
            if a~=0 then
                self.sx=x
                self.sy=y
                self.sc={r,g,b}
            end
        end
        cp:tri()
        print(unpack(self.sc))
    end
end

function cp:getOpColor()

end

function cp:draw()
    love.graphics.setColor(1, 1, 1,1)
    love.graphics.draw(self.canvas,self.x,self.y)
    love.graphics.draw(self.canvas2,self.x,self.y)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.hx, self.hy, self.size/20)
    local c=self.ringDeg-180
    if c<0 then c=c+360 end
    love.graphics.setColor(self:HSVtoRGB(c,1,255))
    love.graphics.circle("line", self.sx, self.sy, self.size/20)
end

return cp
