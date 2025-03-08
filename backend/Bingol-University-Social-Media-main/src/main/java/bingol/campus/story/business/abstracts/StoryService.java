package bingol.campus.story.business.abstracts;

import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.post.core.response.CommentDetailsDTO;
import bingol.campus.post.core.response.LikeDetailsDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.story.core.exceptions.StoryNotActiveException;
import bingol.campus.story.core.exceptions.*;
import bingol.campus.story.core.response.FeatureStoryDTO;
import bingol.campus.story.core.response.StoryDTO;
import bingol.campus.story.core.response.StoryDetails;
import bingol.campus.student.core.response.SearchAccountDTO;
import bingol.campus.student.exceptions.*;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

import javax.xml.crypto.Data;
import java.io.IOException;
import java.util.List;
import java.util.UUID;

public interface StoryService {
    ResponseMessage add(String username, MultipartFile file) throws StudentNotFoundException, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException;

    ResponseMessage delete(String username, UUID storyId) throws StoryNotFoundException, StudentNotFoundException, OwnerStoryException;


    ResponseMessage featureStory(String username, UUID storyId,UUID featuredStoryId) throws StudentNotFoundException, StoryNotFoundException, OwnerStoryException, AlreadyFeaturedStoriesException, FeaturedStoryGroupNotFoundException;


    ResponseMessage extendStoryDuration(String username, UUID storyId, int hours) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException, InvalidHourRangeException, FeaturedStoryModificationException;

    List<SearchAccountDTO> getStoryViewers(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException;

    int getStoryViewCount(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException;

    DataResponseMessage<List<StoryDTO>> getPopularStories(String username) throws StudentNotFoundException;

    DataResponseMessage<List<StoryDTO>> getUserActiveStories(String username, Long userId) throws StudentNotFoundException, BlockingBetweenStudent, NotFollowingException;

    DataResponseMessage<List<CommentDetailsDTO>> getStoryComments(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException;

    DataResponseMessage<StoryDTO> viewStory(String username, UUID storyId) throws StoryNotFoundException, StoryNotActiveException, StudentNotFoundException, NotFollowingException, BlockingBetweenStudent;



    DataResponseMessage<List<LikeDetailsDTO>> getLike(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException;


    DataResponseMessage<List<StoryDetails>> getStories(String username, Pageable pageable) throws StudentNotFoundException;


    DataResponseMessage<StoryDetails> getStoryDetails(String username, UUID storyId, Pageable pageable) throws StudentNotFoundException, StoryNotFoundException, OwnerStoryException;

    ResponseMessage featureUpdate(String username, UUID featureId, String title, MultipartFile file) throws StudentNotFoundException, FeaturedStoryGroupNotFoundException, FeaturedStoryGroupNotAccess, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException;

    DataResponseMessage<FeatureStoryDTO> getFeatureId(String username, UUID featureId) throws StudentNotFoundException, FeaturedStoryGroupNotFoundException, BlockingBetweenStudent, StudentProfilePrivateException;

    DataResponseMessage<List<FeatureStoryDTO>> getFeaturedStoriesByStudent(String username, Long studentId) throws StudentNotFoundException, BlockingBetweenStudent, StudentProfilePrivateException;

    DataResponseMessage<List<FeatureStoryDTO>> getMyFeaturedStories(String username) throws StudentNotFoundException;

    DataResponseMessage<List<StoryDTO>> archivedStories(String username) throws StudentNotFoundException;

    ResponseMessage deleteArchived(String username, UUID storyId);
}
