function CulteDKPButton_OnLoad(self)
	if ( not self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	end
end

function CulteDKPButton_OnMouseDown(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Down");
		self.Middle:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Down");
		self.Right:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Down");
	end
end

function CulteDKPButton_OnMouseUp(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
	end
end

function CulteDKPButton_OnShow(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
	end
end

function CulteDKPButton_OnDisable(self)
	self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
end

function CulteDKPButton_OnEnable(self)
	self.Left:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
	self.Middle:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
	self.Right:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\CulteDKP-Button-Up");
end
