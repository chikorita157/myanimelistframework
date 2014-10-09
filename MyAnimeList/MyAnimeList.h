//
//  MyAnimeList.h
//  MyAnimeList Framework
//
//  Created by 高町なのは on 2014/10/08.
//  Copyright (c) 2014年 Chikorita157's Anime Blog. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import <SBJson/SBJson.h>

//! Project version number for MyAnimeList.
FOUNDATION_EXPORT double MyAnimeListVersionNumber;

//! Project version string for MyAnimeList.
FOUNDATION_EXPORT const unsigned char MyAnimeListVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MyAnimeList/PublicHeader.h>
@interface MyAnimeList : NSObject {
    NSString * Base64Token;
    NSString * MALApiUrl;
    NSString * LastScrobbledTitle;
    NSString * LastScrobbledEpisode;
    NSString * DetectedTitle;
    NSString * DetectedEpisode;
    NSString * DetectedCurrentEpisode;
    NSString * TotalEpisodes;
    NSString * WatchStatus;
    NSString * TitleScore;
    NSString * TitleState;
    NSString * AniID;
    OGRegularExpressionMatch    *match;
    OGRegularExpression    *regex;
    BOOL Success;
    int choice;
    int videoplayer;
}
-(id)initWithuMALAPIURL:(NSString *)URL;
-(void)startscrobbling;
-(BOOL)detectmedia;
-(NSString *)searchanime;
-(NSString *)findaniid:(NSString *)ResponseData;
-(BOOL)checkstatus:(NSString *)titleid;
-(BOOL)updatetitle:(NSString *)titleid;
-(BOOL)addtitle:(NSString *)titleid;
-(void)updatestatus:(NSString *)titleid
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus;
-(void)posttwitterupdate:(NSString *)message;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(int)getScore;
-(int)getWatchStatus;
@end



