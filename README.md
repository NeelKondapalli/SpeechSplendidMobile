# SpeechSplendid

Live app: https://apps.apple.com/us/app/speechsplendid/id6468758043

This is the repo for the SpeechSplendid app. This app allows users to upload recorded speeches and receive feedback on their language patterns and facial expressions. This analysis is conducted through GPT-3.5 and a custom facial emotion classifier.

## How to run

 1. Clone the repo `git clone https://github.com/NeelKondapalli/SpeechSplendid.git`
 2. Ensure `cocoapods` is installed. cd into the project folder and run `pod install`. This will read the Podfile and setup dependencies.
 3. Open the `.xcworkspace` file in XCode. 
 4. In the XCode toolbar, add a new file and make it a `Configuration Settings File`. Name it Config
    - Within `Config.xcconfig`, on a new line, type `API_KEY = YOUR_KEY`, replacing `YOUR_KEY` with your OpenAI API key.
    - Add the key to the `Info.plist` file.
    - Navigate to the project's build info. For both debug and release, click the configuration dropdown and select `Config` as the configuration.
 5. This app needs to be run on a physical device (simulators won't work because they lack a camera). To do this, you will need an Apple Developer account and a development organization.
 6. If you have any questions, feel free to contact me at neel2h06@gmail.com


