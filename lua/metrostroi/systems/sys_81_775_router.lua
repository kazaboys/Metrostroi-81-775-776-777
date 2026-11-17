Metrostroi.DefineSystem("81_775_ROUTER")
TRAIN_SYSTEM.DontAccelerateSimulation = true

function TRAIN_SYSTEM:Initialize()

end

function TRAIN_SYSTEM:Outputs()

end

function TRAIN_SYSTEM:Inputs()
	return {}
end
if TURBOSTROI then return end

function TRAIN_SYSTEM:TriggerInput(name,value)
end

if SERVER then
    function TRAIN_SYSTEM:Think(dT)
		local Train = self.Train
		local Power = Train.SF19.Value*Train.Electric.Power
		Train:SetNW2Int("Roter:Power",Power)
    end
    concommand.Add("775_Last", function(ply, cmd, args)
        if not args[1] then
            print('Использование: 775_Last <название станции>, Для сброса введите 775_Last ""')
            return
        end
        local stationName = table.concat(args, " ")
        for _, ent in pairs(ents.FindByClass("gmod_subway_81-775")) do
            if IsValid(ent) then
                ent:SetNW2String("CIK:LastStationText", stationName)
            end
        end
    end)
else
	function TRAIN_SYSTEM:ClientInitialize()
	end

	local function createFont(name,font,size,w)
        surface.CreateFont("Metrostroi_775_"..name, {
            font = font,
            size = size,
            weight = w,
            blursize = false,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
            extended = true,
            scanlines = false,
        })
    end

    createFont("Router_numbers","Moscow Sans Regular",70,800,0,0,false)
	createFont("Router_station","Moscow Sans Regular",54,400,0,0,false)

	function TRAIN_SYSTEM:ClientThink()
		local Train = self.Train
		if not Train:ShouldDrawPanel("ROUTER") then return end
		if not Train.ROUTER then return end

		render.PushRenderTarget(Train.ROUTER,0,0,500,72)
		render.Clear(0, 0, 0, 0)
		cam.Start2D()
			render.SetScissorRect(0, 0, 500, 72, true)
			surface.SetDrawColor(30,30,30,255)
			surface.DrawRect(0,0,500,72)
			local ok, err = pcall(self.RouteScrean, self, Train)
			if not ok and (not self.LastErrTime or CurTime() - self.LastErrTime > 5) then
				self.LastErrTime = CurTime()
				ErrorNoHalt("[81-775 ROUTER] "..tostring(err).."\n")
			end
			render.SetScissorRect(0, 0, 0, 0, false)
		cam.End2D()
		render.PopRenderTarget()
	end

	function TRAIN_SYSTEM:RouteScrean(Train)
		if Train:GetNW2Int("Roter:Power",0) <= 0 then return end
		if not Train:GetNW2Bool("CIK:Power") then return end

		local line   = Train:GetNW2Int("CIK:Line",1)
		local ls     = Train:GetNW2Int("CIK:LastStation",1)
		local path   = Train:GetNW2Int("CIK:Path",1)
		local route  = Train:GetNW2Int("CIK:Route",0)
		local isLoop = Train:GetNW2Bool("CIK:IsLoop", false)
		local customStation = Train:GetNW2String("CIK:LastStationText", "")

		draw.SimpleText(Format("%03d",route),'Metrostroi_775_Router_numbers',5,36,Color(255,255,255), 0, 1)

		if isLoop then
			local cycle = 16
			local switchTime = 8
			local animTime = 0.5
			local t = CurTime() % cycle

			local currentText, nextText
			if t < switchTime then
				currentText = "| МАРШРУТ"
				nextText = "| ROUTE"
			else
				currentText = "| ROUTE"
				nextText = "| МАРШРУТ"
			end

			local phaseTime = t % switchTime
			local alphaCurr = 255
			local alphaNext = 0
			local yOffsetCurr = 0
			local yOffsetNext = 0

			if phaseTime > (switchTime - animTime) then
				local progress = (phaseTime - (switchTime - animTime)) / animTime
				local smooth = math.EaseInOut and math.EaseInOut(progress, 0, 1) or progress
				alphaCurr = math.Clamp(math.Round(255 * (1 - smooth)), 0, 255)
				alphaNext = math.Clamp(math.Round(255 * smooth), 0, 255)
				yOffsetCurr = -18 * smooth
				yOffsetNext = 18 * (1 - smooth)
			end

			if alphaCurr > 0 then
				draw.SimpleText(currentText,'Metrostroi_775_Router_station',114,36 + yOffsetCurr,Color(255,255,255,alphaCurr), 0, 1)
			end
			if alphaNext > 0 then
				draw.SimpleText(nextText,'Metrostroi_775_Router_station',114,36 + yOffsetNext,Color(255,255,255,alphaNext), 0, 1)
			end
			return
		end

		local stNameRu = ""
		local stNameEn = ""

		if customStation ~= "" then
			stNameRu = customStation
			stNameEn = customStation
		else
			local map = Metrostroi.ANNOUNCER_MAP_775
			local lineData = map and map[line]
			local stations = lineData and lineData.stations
			if not stations then return end
			local idx = path == 2 and (#stations - ls + 1) or ls
			local st = stations[idx]
			if not st then return end
			stNameRu = st.fname or st.name
			stNameEn = st.ename or st.name
		end

		if stNameEn and stNameEn ~= "" and stNameEn ~= stNameRu then
			local cycle = 16
			local switchTime = 8
			local animTime = 0.5
			local t = CurTime() % cycle

			local currentText, nextText
			if t < switchTime then
				currentText = "| "..stNameRu
				nextText = "| "..stNameEn
			else
				currentText = "| "..stNameEn
				nextText = "| "..stNameRu
			end

			local phaseTime = t % switchTime
			local alphaCurr = 255
			local alphaNext = 0
			local yOffsetCurr = 0
			local yOffsetNext = 0

			if phaseTime > (switchTime - animTime) then
				local progress = (phaseTime - (switchTime - animTime)) / animTime
				local smooth = math.EaseInOut and math.EaseInOut(progress, 0, 1) or progress
				alphaCurr = math.Clamp(math.Round(255 * (1 - smooth)), 0, 255)
				alphaNext = math.Clamp(math.Round(255 * smooth), 0, 255)
				yOffsetCurr = -18 * smooth
				yOffsetNext = 18 * (1 - smooth)
			end

			if alphaCurr > 0 then
				draw.SimpleText(currentText,'Metrostroi_775_Router_station',114,36 + yOffsetCurr,Color(255,255,255,alphaCurr), 0, 1)
			end
			if alphaNext > 0 then
				draw.SimpleText(nextText,'Metrostroi_775_Router_station',114,36 + yOffsetNext,Color(255,255,255,alphaNext), 0, 1)
			end
		else
			draw.SimpleText("| "..stNameRu,'Metrostroi_775_Router_station',114,36,Color(255,255,255), 0, 1)
		end
	end
end
