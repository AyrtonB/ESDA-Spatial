# open powershell and run the following
cd C:\Users\Ayrto\Desktop\PhD\PGTA\Spatial\tutorials\ESDA-Spatial\auth
ssh -i ESDA.pem ec2-user@ec2-54-90-146-3.compute-1.amazonaws.com
jupyter lab --no-browser --port=8888

# then in a separate powershell run this
cd C:\Users\Ayrto\Desktop\PhD\PGTA\Spatial\tutorials\ESDA-Spatial\auth
ssh -i ESDA.pem -L 8000:localhost:8888 ec2-user@ec2-54-90-146-3.compute-1.amazonaws.com