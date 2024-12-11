use palomar

DECLARE @clientID int = 1 
--run the following to find the client ID
--Select * From client

DECLARE @enableCountdown nvarchar(10) = 'true', -- options: 'true' or 'false'
	@enableButton nvarchar(10) = 'true', -- options: 'true' or 'false'
	@buttonMessage nvarchar(max) = 'Visit the new Meta',
	@buttonURL nvarchar(max) = '//www.google.com',
	@targetDate nvarchar(max) = '08-15-2024'



update Config.ClientSetting
set NewMetaHeaderConfig = concat('{"enableCountdown":',@enableCountdown,', "enableButton":',@enableButton,', "buttonMessage":"',@buttonMessage,'","buttonURL":"',@buttonURL,'", "targetDate":"',@targetDate,'" }')
where ClientId = @clientID