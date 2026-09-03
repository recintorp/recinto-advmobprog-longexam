# Rafael Alexis Recinto

## INF231MWA

### CTADMDBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics, covering mobile-to-web transactions and building a Facebook-style application named **Moppibook**.

### Project Architecture & Discussion

I like to think of building this app the same way you'd build a good team, where everyone has one clear job to do.

First come the Models. These are like simple blueprints, they just describe what a "post" or a "user" should look like, so every part of the app agrees on the same shape of information.

Next are the Services. Think of these as messengers. They run out to the internet, grab the raw, messy information, and then neatly organize it using the blueprints from the Models, so it comes back clean and ready to use.

Finally, there are the Screens. These are the actual pages you see and tap on your phone, the part everyone actually notices.

So here's how it all comes together: when you open the app, the Screen asks the Service for data. The Service fetches it and tidies it up using the Models. Then the Screen takes that clean data and turns it into the fun, scrollable feed you actually interact with.

It's a small team with a clear chain of command, and that's exactly what makes the app feel fast and organized under the hood.