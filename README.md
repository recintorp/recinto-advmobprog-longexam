# Rafael Alexis Recinto

## INF231MWA

### CTADMDBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics, covering mobile-to-web transactions and building a Facebook-style application named **Moppibook**.

### Project Architecture & Discussion

I built this app like a well-organized team where everyone has a specific job. First, I created the Models, which act as simple blueprints telling the app what a post or user looks like. Next, I set up the Services, which act as the messengers that travel out to the internet to grab raw information and pack it neatly using those blueprints. Finally, I designed the Screens, which are the actual pages you see and tap on your phone. When you open the app, your screen asks the service for data, the service fetches and cleans it up using the models, and the screen instantly turns that data into a fun, interactive feed.