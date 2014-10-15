//
//  MyAnimeList.m
//  MyAnimeList Framework
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2011 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import "MyAnimeList.h"
//#import "ASIHTTPRequest.h"
//#import "ASIFormDataRequest.h"

@implementation MyAnimeList

-(id)initWithuMALAPIURL:(NSString *)URL{
    //Initalize object with uMAL API URL
    if (self = [super init]) {
        MALApiUrl = [NSString stringWithFormat:@"%@", URL];
    }
    return self;
}

/* 
 
 Accessors
 
 */
-(NSString *)getLastScrobbledTitle
{
    return LastScrobbledTitle;
}
-(NSString *)getLastScrobbledEpisode
{
    return LastScrobbledEpisode;
}
-(NSString *)getAniID
{
    return AniID;
}
-(NSString *)getTotalEpisodes
{
	return TotalEpisodes;
}
-(int)getScore
{
    return [TitleScore integerValue];
}
-(int)getWatchStatus
{
	if ([WatchStatus isEqualToString:@"watching"])
		return 0;
	else if ([WatchStatus isEqualToString:@"completed"])
		return 1;
	else if ([WatchStatus isEqualToString:@"on-hold"])
		return 2;
	else if ([WatchStatus isEqualToString:@"dropped"])
		return 3;
	else
		return 0; //fallback
}

/*
 
 Update Methods
 
 */

- (int)scrobble {
    // 0 - New Tite; 1 = Update Title; 2 - No Update; 3 = Failure
    // Empty out Detected Title/Episode to prevent same title detection
    DetectedTitle = @"";
    DetectedEpisode = @"";
	//Set up Delegate
	//MAL_Updater_OS_XAppDelegate* appDelegate=[NSApp delegate];
	if ([self detectmedia] == 1) { // Detects Title
		//[appDelegate setStatusText:@"Scrobble Status: Scrobbling..."];
		NSLog(@"Getting AniID");
        AniID = [self findaniid:[self searchanime:DetectedTitle]];
		if (AniID.length > 0) {
            NSLog(@"Found %@", AniID);
			// Check Status and Update
			BOOL UpdateBool = [self checkstatus:AniID];
			if (UpdateBool == 1) {
			if ([WatchStatus isEqualToString:@"Nothing"]) {
				//Title is not on list. Add Title
				Success = [self addtitle:AniID];
                return 0;
			}
			else {
				// Update Title as Usual
				Success = [self updatetitle:AniID];
                return 1;
			}
				//Set last successful scrobble to statusItem Tooltip
				//[appDelegate setStatusToolTip:[NSString stringWithFormat:@"MAL Updater OS X - Last Scrobble: %@ - %@", LastScrobbledTitle, LastScrobbledEpisode]];
                return 2;
			}
		}
		else {
			// Not Successful
			//[appDelegate setStatusText:@"Scrobble Status: Can't find title. Retrying in 5 mins..."];
			/*[GrowlApplicationBridge notifyWithTitle:@"Scrobble Unsuccessful."
										description:@"Can't find title. Retrying in 5 mins..."
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];*/
            return 3;
		}
        return 3;
    }
return 3;
}
-(NSArray *)searchanime:(NSString *)title{
	NSLog(@"Searching For Title");
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Escape Search Term
	NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																				NULL,
																				(CFStringRef)title,
																				NULL,
																				(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																				kCFStringEncodingUTF8 ));
	//MALApiUrl = [defaults objectForKey:@"MALAPIURL"]; #to be removed

	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/search?q=%@",MALApiUrl, searchterm]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
    NSDictionary *requestHeaders = [NSDictionary
                                    dictionaryWithObject:[NSString stringWithFormat:@"Basic %@",Base64Token] forKey:@"Authorization"];
	//Perform Search
	[request startSynchronous];
	//Set up Delegate
	//MAL_Updater_OS_XAppDelegate* appDelegate=[NSApp delegate];
	// Get Status Code
	int statusCode = [request responseStatusCode];
			NSString *response = [request responseString];
    NSArray *searchdata;
	switch (statusCode) {
		case 200:
            // Initalize JSON parser
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            searchdata = [parser objectWithString:response];/*[parser objectWithString:ResponseData error:nil]*/;
			//Return Search Results as an array
			return searchdata;//[self findaniid:response];
			break;
			
		case 0:
			Success = NO;
			/*[appDelegate setStatusText:@"Scrobble Status: No Internet Connection."];
			[GrowlApplicationBridge notifyWithTitle:@"Scrobble Unsuccessful."
										description:@"No Internet Connection. Retrying in 5 mins"
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];*/
			return searchdata;
			break;

		case 500:
		case 502:
			Success = NO;
			/*[appDelegate setStatusText:@"Scrobble Status: Unofficial MAL API is unaviliable."];
			[GrowlApplicationBridge notifyWithTitle:@"Scrobble Unsuccessful."
										description:@"Unofficial MAL API is unaviliable. Contact the Unofficial MAL API Developers."
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];*/
			return searchdata;
			break;
			
		default:
			Success = NO;
			/*[appDelegate setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
			[GrowlApplicationBridge notifyWithTitle:@"Scrobble Unsuccessful."
										description:@"Retrying in 5 mins..."
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];*/
			return searchdata;
			break;
	}
	
}
-(NSDictionary *)detectmedia {
	//Set up Delegate
	//MAL_Updater_OS_XAppDelegate* appDelegate=[NSApp delegate];
	// LSOF mplayer to get the media title and segment
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/sbin/lsof"];
	NSString * player;
	//Load Selected Player from Preferences
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Player Selection
	switch (videoplayer) {
		case 0:
			player = @"mplayer";
			break;
		case 1:
			player = @"QTKitServer";
			break;
		case 2:
			player = @"VLC";
			break;
		case 3:
			player = @"QuickTime Player";
			break;
		default:
			break;
	}
	//lsof -c '<player name>' -Fn		
	[task setArguments: [NSArray arrayWithObjects:@"-c", player, @"-F", @"n", nil]];
		
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	if (string.length > 0) {
		//Regex time
		//Get the filename first
		regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm)$"];
		NSEnumerator    *enumerator;
		enumerator = [regex matchEnumeratorInString:string];		
		while ((match = [enumerator nextObject]) != nil) {
			string = [match matchedString];
		}
        NSString * DetectedEpisode;
        NSString * DetectedTitle;
		//Accented e temporary fix
		regex = [OGRegularExpression regularExpressionWithString:@"e\\\\xcc\\\\x81"];
		string = [regex replaceAllMatchesInString:string
									   withString:@"è"];
		//Cleanup
		regex = [OGRegularExpression regularExpressionWithString:@"^.+/"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"\\.\\w+$"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\[[^\\]]+\\]\\s*"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\([^\\)]+\\)$"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"_"];
		string = [regex replaceAllMatchesInString:string
									   withString:@" "];
		// Set Title Info
		regex = [OGRegularExpression regularExpressionWithString:@"( \\-) (episode |ep |ep|e)?(\\d+)([\\w\\-! ]*)$"];
		DetectedTitle = [regex replaceAllMatchesInString:string
														 withString:@""];
		// Set Episode Info
		regex = [OGRegularExpression regularExpressionWithString:@" - "];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString: DetectedTitle];
		string = [regex replaceAllMatchesInString:string
												withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"v[\\d]"];
		DetectedEpisode = [regex replaceAllMatchesInString:string
												withString:@""];
		// Trim Whitespace

		DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		DetectedEpisode = [DetectedEpisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		//release
		regex = nil;
		enumerator = nil;
		string = @"";
        //Create Dictionary
        NSMutableDictionary *resultdic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"DetectedTitle", DetectedTitle, @"DetectedEpisode",DetectedEpisode, @"DetectSuccess", [NSNumber numberWithBool:NO], nil];
		// Check if the title was previously scrobbled
		if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
			// Do Nothing
			/*[appDelegate setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
			[appDelegate setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];*/
            [resultdic setObject:[NSNumber numberWithBool:YES] forKey:@"DetectSuccess"];
             }
		else {
            // Not Scrobbled Yet or Unsuccessful
            [resultdic setObject:[NSNumber numberWithBool:NO] forKey:@"DetectSuccess"];

		}
        return resultdic;
	}
	else {
		// Nothing detected
		//[appDelegate setStatusText:@"Scrobble Status: Idle..."];

	}
}
-(NSString *)findaniid:(NSArray *)searchdata {
	NSString *titleid = @"";
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
	//Set Regular Expressions to omit any preceding words
	NSString *findpre = [NSString stringWithFormat:@"(%@)",DetectedTitle];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"]; // NSString *findpre = [NSString stringWithFormat:@"^%@",DetectedTitle];
	regex = [OGRegularExpression regularExpressionWithString:findpre];
	//Retrieve the ID. Note that the most matched title will be on the top
	for (NSDictionary *serchentry in searchdata) {
		//Store title from search entry
		theshowtitle = [NSString stringWithFormat:@"%@",[serchentry objectForKey:@"title"]];
		//Test each title until it matches
		if ([regex matchInString:theshowtitle] != nil) {
			//Return titleid
			titleid = [NSString stringWithFormat:@"%@",[serchentry objectForKey:@"id"]];
			goto foundtitle;
		}
	}
foundtitle:
	//Return the AniID
	return titleid;
}
-(BOOL)checkstatus:(NSString *)titleid {
	NSLog(@"Checking Status");
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/%@?mine=1",MALApiUrl, titleid]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	NSDictionary *requestHeaders = [NSDictionary
                                    dictionaryWithObject:[NSString stringWithFormat:@"Basic %@",Base64Token] forKey:@"Authorization"];
	//Perform Search
	[request startSynchronous];
	// Get Status Code
	int statusCode = [request responseStatusCode];
	NSString *response = [request responseString];
	if (statusCode == 200 ) {
		// Initalize JSON parser
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        NSDictionary *animeinfo = [parser objectWithString:response];
		if ([animeinfo objectForKey:@"episodes"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
			TotalEpisodes = @"0"; // No Episode Total, Set to 0.
		}
		else { // Episode Total Exists
			TotalEpisodes = [animeinfo objectForKey:@"episodes"];
		}
		DetectedCurrentEpisode = [animeinfo objectForKey:@"watched_episodes"];
		// Watch Status
		if ([animeinfo objectForKey:@"watched_status"] == [NSNull null]) {
			NSLog(@"Not on List");
			WatchStatus = @"Nothing";
			TitleScore = @"0"; 
		}
		else {
			NSLog(@"Title on List");
			WatchStatus = [animeinfo objectForKey:@"watched_status"];
			if ([animeinfo objectForKey:@"score"] == [NSNull null]){
				// Score is null, set to 0
				TitleScore = @"0";
			}
			else {
				TitleScore = [animeinfo objectForKey:@"score"]; 
			}
			NSLog(@"Title Score %@", TitleScore);
		}
		return YES;
	}
	else {
		// Some Error. Abort
		//Set up Delegate
		/*MAL_Updater_OS_XAppDelegate* appDelegate=[NSApp delegate];
		[appDelegate setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];*/
		return NO;
	}
	//Should never happen, but...
	return NO;
}
-(BOOL)updatetitle:(NSString *)titleid {
	NSLog(@"Updating Title");
	//Set up Delegate
	if ([DetectedEpisode intValue] <= [DetectedCurrentEpisode intValue] ) { 
		// Already Watched, no need to scrobble
		/*[appDelegate setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
		[appDelegate setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];*/
        // Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
		return YES;
	}
	else {
		// Update the title
		//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//Set library/scrobble API
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime/%@", MALApiUrl, titleid]];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		//Ignore Cookies
		[request setUseCookiePersistence:NO];
		//Set Token
		NSDictionary *requestHeaders = [NSDictionary
                                    dictionaryWithObject:[NSString stringWithFormat:@"Basic %@",Base64Token] forKey:@"Authorization"];
	    [request setPostValue:@"PUT" forKey:@"_method"];
	    [request setPostValue:DetectedEpisode forKey:@"episodes"];
		//Set Status
		if([DetectedEpisode intValue] == [TotalEpisodes intValue]) {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"completed";
			// Since Detected Episode = Total Episode, set the status as "Complete"
			[request setPostValue:WatchStatus forKey:@"status"];
		}
		else {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"watching";
			// Still Watching
			[request setPostValue:WatchStatus forKey:@"status"];
		}	
		// Set existing score to prevent the score from being erased.
		[request setPostValue:TitleScore forKey:@"score"];
		// Do Update
		[request startSynchronous];
		
		// Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
		
		switch ([request responseStatusCode]) {
			case 200:
				// Update Successful
				/*[appDelegate setStatusText:@"Scrobble Status: Scrobble Successful..."];
				[appDelegate setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
				[GrowlApplicationBridge notifyWithTitle:@"Scrobble Successful."
											description:[NSString stringWithFormat:@"%@ - %@",DetectedTitle,DetectedEpisode]
									   notificationName:@"Message"
											   iconData:nil
											   priority:0
											   isSticky:NO
										   clickContext:[NSDate date]];*/
				//Add History Record
				//[appDelegate addrecord:DetectedTitle Episode:DetectedEpisode Date:[NSDate date]];
				return YES;
				break;
			default:
				// Update Unsuccessful
				/*[appDelegate setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
				[GrowlApplicationBridge notifyWithTitle:@"Scrobble Unsuccessful."
											description:@"Retrying in 5 mins..."
									   notificationName:@"Message"
											   iconData:nil
											   priority:0
											   isSticky:NO
										   clickContext:[NSDate date]];*/
				return NO;
				break;
		}

	}
}
-(BOOL)addtitle:(NSString *)titleid {
	NSLog(@"Adding Title");
	//Set up Delegate
	MAL_Updater_OS_XAppDelegate* appDelegate=[NSApp delegate];
	// Add the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime", MALApiUrl]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	NSDictionary *requestHeaders = [NSDictionary
                                    dictionaryWithObject:[NSString stringWithFormat:@"Basic %@",Base64Token] forKey:@"Authorization"];
	[request setPostValue:titleid forKey:@"anime_id"];
	[request setPostValue:DetectedEpisode forKey:@"episodes"];
	[request setPostValue:@"watching" forKey:@"status"];	
	// Do Update
	[request startSynchronous];

	// Store Scrobbled Title and Episode
	LastScrobbledTitle = DetectedTitle;
	LastScrobbledEpisode = DetectedEpisode;
	
	//Set Title State for Title (use for Twitter feature)
	TitleState = @"started watching";
	WatchStatus = @"watching";

	switch ([request responseStatusCode]) {
		case 200:
			// Update Successful
			/*[appDelegate setStatusText:@"Scrobble Status: Title Added..."];
			[appDelegate setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - %@",DetectedTitle,DetectedEpisode]];
			[GrowlApplicationBridge notifyWithTitle:@"Adding of Title Successful."
										description:[NSString stringWithFormat:@"%@ - %@",DetectedTitle,DetectedEpisode]
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];*/
			//Add History Record
			/*[appDelegate addrecord:DetectedTitle Episode:DetectedEpisode Date:[NSDate date]];*/
			return YES;
			break;
		default:
			// Update Unsuccessful
			/*[appDelegate setStatusText:@"Scrobble Status: Adding of Title Failed. Retrying in 5 mins..."];
			[GrowlApplicationBridge notifyWithTitle:@"Adding of Title Unsuccessful."
										description:@"Retrying in 5 mins..."
								   notificationName:@"Message"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:[NSDate date]];*/
			return NO;
			break;
	}
}
-(void)updatestatus:(NSString *)titleid
			 score:(int)showscore
	   watchstatus:(NSString*)showwatchstatus
{
	NSLog(@"Updating Status for %@", titleid);
	//Set up Delegate
	/*MAL_Updater_OS_XAppDelegate* appDelegate=[NSApp delegate];*/
	// Update the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/animelist/anime/%@", MALApiUrl, titleid]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
	NSDictionary *requestHeaders = [NSDictionary
                                    dictionaryWithObject:[NSString stringWithFormat:@"Basic %@",Base64Token] forKey:@"Authorization"];
	[request setPostValue:@"PUT" forKey:@"_method"];
	//Set current episode
	[request setPostValue:LastScrobbledEpisode forKey:@"episodes"];
	//Set new watch status
	[request setPostValue:showwatchstatus forKey:@"status"];	
	//Set new score.
	[request setPostValue:[NSString stringWithFormat:@"%i", showscore] forKey:@"score"];
	// Do Update
	[request startSynchronous];
	
	switch ([request responseStatusCode]) {
		case 200:
			// Update Successful
			[appDelegate setStatusText:@"Scrobble Status: Updating of Watch Status/Score Successful."];
			if ([TitleScore isEqualToString:[NSString stringWithFormat:@"%i", showscore]] && [WatchStatus isEqualToString:showwatchstatus])
			{
				//Nothing changed, do nothing.
			}
			else {
            
			}
			//Set New Values
			TitleScore = [NSString stringWithFormat:@"%i", showscore];
			WatchStatus = showwatchstatus;
			break;
		default:
			// Update Unsuccessful
			/*[appDelegate setStatusText:@"Scrobble Status: Unable to update Watch Status/Score."];*/
			break;
	}
	
}
-(void) changeuMALAPIURL:(NSString *)URL{
    MALApiUrl = [NSString stringWithFormat:@"%@", URL];
}
-(void) setAuthToken:(NSString *)token{
    
}
-(int) verifyCredentials:(NSString *)username
                password:(NSString *)password{
    
}
@end
