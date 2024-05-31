-- Made by denzio321 for purposes of HD application
--BrainFuck visual interpreter 1.0
--Guide:
--A visual cell are the cubes that show up in the 3d game, these represent the values of the actual cells.
--To learn more about this visit https://gist.github.com/roachhd/dce54bec8ba55fb17d3a for a guide on brainfuck, its a really good guide frfr
local Machine = script.Parent--The Folder of all the parts of the BrainFuck Visual representation
local Arrow = Machine.Arrow--The arrow representing the current pointer's position
local Output = Machine.OutputPart.OutputGui.Output--Output TextLabel
local Input = Machine.Input.InputGui.Input--Input text box(Decided not to implement input cuz lazy frfr)
local Submit = Machine.Input.InputGui.Submit--The submit button for input but not used due to reason above
local Wall = Machine.Wall--The place where cells enter or exit
local Cells = Machine.Cells--A folder for all the visual cells
local Cell = game.ReplicatedStorage.Cell--The part which is the visual representation of a cell, it has a textlabel as a child to show its current value
local CellNum = Machine.CellNum.Value--The number of cells show at one time
local GuiCells = {}--A table representing ordering the Visual cells
local GraphicalOffset = 0--The Offset of which the cells are displayed
-- lets say u have an array of 5 cells and you display two of them
-- |1 2| 3 4 5 this is a graphical offset of 0
-- 1 |2 3| 4 5 this is a graphical offset of 1
-- 1 2 |3 4| 5 this is a graphical offset of 2 etc
local CellValues = {}-- The numerical representation for the cells, length has no limit(dynamic array)
local ptVal = 1--pointer val representing current position of the pointer
local TweenService = game:GetService('TweenService')--TweenService cuz there's a lotttt of tweening here lmao
--visual functions
local function setGuiCell()
	for i,v in GuiCells do
		CellValues[i+GraphicalOffset] = CellValues[i+GraphicalOffset] or 0 --set the cell to value if it exists else set it to 0(I mean this is alr handled in initCell but just incase ig)
		v:WaitForChild('SurfaceGui'):WaitForChild('Value').Text = tostring(CellValues[i+GraphicalOffset])--set the text value of the textbox to the value of the cell
	end
end
local function insertCell(dir)-- dir=1:insert from the front, dir=-1:insert from the back
	local idx
	if dir == -1 then
		idx = #GuiCells--set target to back
	else
		idx = 1--set target to front
	end
	local Cell_Clone = Cell:Clone()
	local Pos = GuiCells[idx].Position+(-dir*Cell_Clone.CFrame.RightVector*Cell_Clone.Size.X)-- put cell at right/left target if the dir is from the back/front
	Cell_Clone.CFrame = Wall.CFrame.Rotation+Pos
	if dir == -1 then
		idx += 1--because table.insert() moves additional indices to the back,including the index we're inserting at, we need to increment our idx by 1 if we're putting it at the back
	end
	table.insert(GuiCells,idx,Cell_Clone)
	setGuiCell()--set the gui text of the cell
	Cell_Clone.Parent = Cells
end
local function initMachine()--spawns in all the cells & stuff goated function
	--really should've made a function for all this positioning in hindsight but im too lazy to change it now
	local lastPos
	local Pos = Wall.Position-(Wall.CFrame.RightVector*((Wall.Size.X+Cell.Size.X)/2))--Positions cell such that its right side touches the walls left side


	for i=1,CellNum-1 do
		local Cell_Clone = Cell:Clone()
		Cell_Clone.CFrame = Wall.CFrame.Rotation+Pos-- Makes sure the cell is parallel to the wall and sets the position
		Cell_Clone.Parent=Cells
		lastPos = Pos--need this to set the other wall later
		Pos = Cell_Clone.Position-(Cell_Clone.CFrame.RightVector*Cell_Clone.Size.X)--Positions cell such that its right side touches the previous cell's left side
		table.insert(GuiCells,Cell_Clone)--inserts Cell into the guiCells table woooo
	end

	local WallEnd = Wall:Clone()
	WallEnd.CFrame = Wall.CFrame.Rotation+(lastPos-(Wall.CFrame.RightVector*((Wall.Size.X+Cell.Size.X)/2)))--sets the wall with the same logic we used to set the initial position
	WallEnd.Parent = Machine
end
local function moveArrowTo(idx)
	local Tweeninf = TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false,0)
	local tween = TweenService:Create(Arrow,Tweeninf,{Position=GuiCells[idx].Position+Vector3.new(0,5,0)})--Tweens arrow position to be on top of cell at position idx by 5 studs
	tween:Play()
	tween.Completed:Wait()
end
local function popFront()
	GuiCells[1]:Destroy()--destroy cell at front
	table.remove(GuiCells,1)--remove cell from table
end
local function popBack()
	GuiCells[#GuiCells]:Destroy()--destroy cell at front
	table.remove(GuiCells,#GuiCells)--remove cell from table
end
local function tweenModel(model,idx)--for plus,minus indicators
	local cell = GuiCells[idx]-- get cell to tween to
	local model_C = model:Clone()-- clone the mode;(plus or minus sign)
	model_C:PivotTo(cell.CFrame+Vector3.new(0,10,0))--Set model position to be ten studs above cell
	local CFrameVal = Instance.new('CFrameValue')--make cf value so we can tween model
	CFrameVal.Parent = model_C
	model_C.Parent = Machine
	CFrameVal.Value = cell.CFrame+Vector3.new(0,10,0)
	CFrameVal.Changed:Connect(function()
		model_C:PivotTo(CFrameVal.Value)--when cf value changed by tween, pivot cloned model to the cframe 
	end)
	local Tweeninf = TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false,0)--tween info
	local tween = TweenService:Create(CFrameVal,Tweeninf,{Value=cell.CFrame})--create the tween
	tween:Play()--play tween
	tween.Completed:Wait()--wait for tween to end
	model_C:Destroy()--destroy indicator/model
end
local function shiftCellsDir(dir)
	local tweens = {}--make a table for the tweens to iterate through later to avoid delays
	insertCell(dir)
	for i,CurrentCell in GuiCells do
		local TargetPos = CurrentCell.Position+(dir*Cell.CFrame.RightVector*Cell.Size.X)--Same positioning logic as used in initMachine(dang should've created a function for this shit)
		local Tweeninf = TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false,0)
		local tween = TweenService:Create(CurrentCell,Tweeninf,{Position=TargetPos})--create tween
		table.insert(tweens,tween)--insert tween into table to be called together later
	end
	local finished = 0
	for i,v in tweens do -- play all the tweens
		v:Play()
		v.Completed:Connect(function()
			finished +=1--add one to the finished variable
		end)
	end
	repeat wait() until finished == #GuiCells --wait for all tweens to be finished
	if dir == 1 then
		popBack()--pop the back cell since its gone into the wall
	else
		popFront()--pop the front cell since its gone into the wall
	end
end
--BF handler Functions(Basically the part that actually executes the brainfuck code)
local busy = false--debounce but idk busy feels like a better name for it

local function execute(code)
	if busy then return end-- if we'e executing code currently dont disturb
	busy = true
	moveArrowTo(1)--move arrow to first cell
	CellValues = {}--make cellvalues empty 
	ptVal = 1--set cell value to first cell
	GraphicalOffset = 0
	setGuiCell()--Set all cells to 0
	local currentScope = {}
	local codePt = 1--represents the index of the char in the string of code we're reading
	local BF_Operators = {}--functions for +-<>
	local function initCell()
		if not CellValues[ptVal] then
			CellValues[ptVal] = 0--if cell is nil define the cell as 0(starting value)
		end
	end
	local function moveWindow()
		-- if pt goes out of bounds shift graphicaloffset by 1 or -1 to keep pt in bounds
		if ptVal>=CellNum+GraphicalOffset then
			GraphicalOffset += 1
			shiftCellsDir(-1)
		elseif ptVal<=GraphicalOffset then
			GraphicalOffset -= 1
			shiftCellsDir(1)
		end
	end
	BF_Operators['+'] = function()--plus op
		initCell()
		tweenModel(game.ReplicatedStorage.Plus,ptVal-GraphicalOffset)--tween plus model to current cell pt is at
		CellValues[ptVal] += 1-- add one to cell
	end
	BF_Operators['-'] = function()--minus op
		initCell()
		tweenModel(game.ReplicatedStorage.Minus,ptVal-GraphicalOffset)--tween plus model to current cell pt is at
		CellValues[ptVal] -= 1-- subtract one from cell
	end
	BF_Operators['<'] = function()--shift pt left
		if ptVal > 1 then-- if cell is more than shift cell to left
			ptVal -= 1
		end
		initCell()
		moveWindow()--check if pt is out of bound after shift and remedy via shifting if so
		setGuiCell()
		moveArrowTo(ptVal-GraphicalOffset)
	end
	BF_Operators['>'] = function()--shift pt right
		ptVal += 1--shift cell to right
		initCell()
		moveWindow()--check if pt is out of bound after shift and remedy via shifting if so
		setGuiCell()
		moveArrowTo(ptVal-GraphicalOffset)
	end
	BF_Operators['.'] = function()
		Output.Text = Output.Text..string.char(CellValues[ptVal])--output text based from ascii code
	end
	task.wait(1)
	initCell()
	local loopPt
	local Halt = false
	game.ReplicatedStorage.Halt.OnServerEvent:Connect(function()--Event that user can trigger in case of infinite loop
		Halt = true
	end)
	while codePt<=#code and not Halt do
		local char = string.sub(code,codePt,codePt)
		if BF_Operators[char] then
			BF_Operators[char]()
			--over flow code. usually brainfuck cells range from 0-255(octet) so if that value is exceeded a overflow occurs some people use this in bf codes
			if CellValues[ptVal] < 0 then-- if less than 0 over flow back to 255
				CellValues[ptVal] = 255
			elseif CellValues[ptVal] > 255 then-- more than 255, overflow back to 0
				CellValues[ptVal] = 0
			end
		elseif char == '[' then--open loop bracket
			if CellValues[ptVal]==0 then-- if loop starts when cell is zero skip to end
				print(codePt)
				local count = 1
				while count~=0 do
					codePt+=1 --checks that we go to the bracket pair
					local theChar = string.sub(code,codePt,codePt)
					if theChar==']' then
						count-=1
					elseif theChar=='[' then
						count += 1
					end
				end
			else
				currentScope = {Start=codePt,lastScope=currentScope}
			end
			
		elseif char == ']' then--close loop bracket
			if CellValues[ptVal]==0 then
				currentScope = currentScope.lastScope
			else
				codePt = currentScope.Start -- go back to the code pt set by open loop bracket
			end
		end
		task.wait()-- just in case the loop is too fast somehow
		setGuiCell()--set the values of the visual cells
		
		codePt += 1--read the next character of the code
	end
	busy = false
end

initMachine()--intialize machine
game.ReplicatedStorage.Code.OnServerEvent:Connect(function(player,codeLocal) -- a gui a user can input code from can fire an event to submit code
	if busy then return end -- make sure code isnt running atm
	Output.Text = '' --reset output text
	execute(codeLocal)--execute code
end)

