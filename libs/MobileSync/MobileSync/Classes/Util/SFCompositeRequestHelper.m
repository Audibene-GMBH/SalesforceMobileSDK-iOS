/*
 Copyright (c) 2019-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <SalesforceSDKCore/SFSDKCompositeResponse.h>
#import "SFCompositeRequestHelper.h"
#import "SFMobileSyncNetworkUtils.h"
#import "SFMobileSyncConstants.h"

@implementation SFCompositeRequestHelper

+ (void)sendCompositeRequest:(SFMobileSyncSyncManager *)syncManager
                   allOrNone:(BOOL)allOrNone
                      refIds:(NSArray<NSString *> *)refIds
                    requests:(NSArray<SFRestRequest *> *)requests
             completionBlock:(SFSendCompositeRequestCompleteBlock)completionBlock
                   failBlock:(SFSyncUpTargetErrorBlock)failBlock {
    SFRestRequest *compositeRequest = [[SFRestAPI sharedInstance] compositeRequest:requests refIds:refIds allOrNone:allOrNone apiVersion:nil];
    [SFMobileSyncNetworkUtils sendRequestWithMobileSyncUserAgent:compositeRequest
                                                     failureBlock:^(id response, NSError *e, NSURLResponse *rawResponse) {
                                                         failBlock(e);
                                                     }
                                                 successBlock:^(id response, NSURLResponse *rawResponse) {
                                                     SFSDKCompositeResponse* compositeResponse = [[SFSDKCompositeResponse alloc] initWith:response];
                                                     NSMutableDictionary *refIdToResponses = [NSMutableDictionary new];
                                                     for (SFSDKCompositeSubResponse *response in compositeResponse.subResponses) {
                                                         refIdToResponses[response.referenceId] = response;
                                                     }
                                                     completionBlock(refIdToResponses);
                                                 }];
}

+ (NSDictionary<NSString*, NSString*> *)parseIdsFromResponses:(NSArray<SFSDKCompositeResponse*>*)responses {
    NSMutableDictionary *refIdToId = [NSMutableDictionary new];
    for (SFSDKCompositeSubResponse* response in responses) {
        if (response.httpStatusCode == 201) {
            NSString *serverId = response.body[kCreatedId];
            refIdToId[response.referenceId] = serverId;
        }
    }
    return refIdToId;
}

+ (void)updateReferences:(NSMutableDictionary *)record
          fieldWithRefId:(NSString *)fieldWithRefId
         refIdToServerId:(NSDictionary *)refIdToServerId {
    
    NSString *refId = record[fieldWithRefId];
    if (refId && refIdToServerId[refId]) {
        record[fieldWithRefId] = refIdToServerId[refId];
    }
}



@end