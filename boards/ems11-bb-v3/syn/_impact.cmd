setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "E:/GitHub/sirchuckalot/zet/boards/ems11-bb-v3/syn/kotku.bit"
Program -p 1 
Program -p 1 
Program -p 1 
Program -p 1 
setMode -bs
setMode -bs
deleteDevice -position 1
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
