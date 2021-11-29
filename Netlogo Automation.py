import pandas as pd

import pyNetLogo
netlogo = pyNetLogo.NetLogoLink(gui=True)
netlogo.load_model('./MyRobot.nlogo')

percent_clean = 0 

netlogo.command('setup')

while percent_clean < 95:

	netlogo.command('go')
	percent_clean = netlogo.report('pct-clean')
	print (percent_clean)


print ('Cleaning Complete!')
print ('Take screen shot and save')
print ('Query ticks and add to CSV')

