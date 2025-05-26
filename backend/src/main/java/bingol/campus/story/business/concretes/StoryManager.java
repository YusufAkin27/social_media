package bingol.campus.story.business.concretes;

import bingol.campus.comment.core.converter.CommentConverter;
import bingol.campus.comment.entity.Comment;
import bingol.campus.config.MediaUploadService;
import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.like.core.converter.LikeConverter;
import bingol.campus.like.entity.Like;
import bingol.campus.notification.NotificationController;
import bingol.campus.notification.SendBulkNotificationRequest;
import bingol.campus.post.core.response.CommentDetailsDTO;
import bingol.campus.post.core.response.LikeDetailsDTO;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;

import bingol.campus.story.business.abstracts.StoryService;
import bingol.campus.story.core.exceptions.*;
import bingol.campus.story.core.converter.StoryConverter;
import bingol.campus.story.core.response.FeatureStoryDTO;
import bingol.campus.story.core.response.StoryDTO;
import bingol.campus.story.core.response.StoryDetails;

import bingol.campus.story.entity.FeaturedStory;
import bingol.campus.story.entity.Story;

import bingol.campus.story.entity.StoryViewer;
import bingol.campus.story.repository.FeaturedStoryRepository;
import bingol.campus.story.repository.StoryRepository;
import bingol.campus.story.repository.StoryViewerRepository;
import bingol.campus.student.core.converter.StudentConverter;
import bingol.campus.student.core.response.SearchAccountDTO;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.*;
import bingol.campus.student.repository.StudentRepository;
import com.cloudinary.Cloudinary;

import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StoryManager implements StoryService {
    private final StudentRepository studentRepository;
    private final StoryRepository storyRepository;
    private final MediaUploadService mediaUploadService;
    private final StoryConverter storyConverter;
    private final StudentConverter studentConverter;
    private final FeaturedStoryRepository featuredStoryRepository;
    private final CommentConverter commentConverter;
    private final StoryViewerRepository storyViewerRepository;
    private final LikeConverter likeConverter;
    private final NotificationController notificationController;

    @Override
    @Transactional
    public ResponseMessage add(String username, MultipartFile file) throws StudentNotFoundException, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException {
        Student student = studentRepository.getByUserNumber(username);
        if (student == null) {
            throw new StudentNotFoundException();
        }

        Story story = new Story();
        story.setActive(true);
        story.setComments(new ArrayList<>());
        story.setLikes(new ArrayList<>());
        story.setCreatedAt(LocalDateTime.now());
        story.setExpiresAt(LocalDateTime.now().plusHours(24));
        story.setStudent(student);

        if (file != null && !file.isEmpty()) {
            CompletableFuture<String> stringCompletableFuture = mediaUploadService.uploadAndOptimizeMedia(file);
            String url = stringCompletableFuture.join();
            story.setPhoto(url);
        }


        student.getStories().add(story);
        storyRepository.save(story);
        studentRepository.save(student);

        List<String> fcmTokens = student.getFollowers().stream()
                .filter(f -> f.getFollowed().getFcmToken() != null && f.getFollowed().getIsActive())
                .map(f -> f.getFollowed().getFcmToken())
                .collect(Collectors.toList());

        if (!fcmTokens.isEmpty()) {
            SendBulkNotificationRequest sendBulkNotificationRequest = new SendBulkNotificationRequest();
            sendBulkNotificationRequest.setTitle("Yeni Hikaye");
            sendBulkNotificationRequest.setMessage(student.getUsername() + " yeni bir hikaye paylaştı.");
            sendBulkNotificationRequest.setFmcTokens(fcmTokens);

            try {
                notificationController.sendToUsers(sendBulkNotificationRequest);
            } catch (Exception e) {
                System.err.println("Bildirim gönderme hatası: " + e.getMessage());
            }
        } else {
            System.out.println("Takipçiler arasında bildirim gönderilecek FCM token'ı bulunamadı.");
        }

        return new ResponseMessage("Hikaye başarıyla eklendi.", true);
    }


    @Override
    @Transactional
    public ResponseMessage delete(String username, UUID storyId)
            throws StoryNotFoundException, StudentNotFoundException, OwnerStoryException {
        Student student = studentRepository.getByUserNumber(username);
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);

        if (!student.getStories().contains(story)) {
            throw new OwnerStoryException();
        }
        student.getStories().remove(story);
        student.getArchivedStories().add(story);
        studentRepository.save(student);
        return new ResponseMessage("Hikaye arşive alındı.", true);
    }

    @Override
    public DataResponseMessage<StoryDetails> getStoryDetails(String username, UUID storyId, Pageable pageable) throws StudentNotFoundException, StoryNotFoundException, OwnerStoryException {
        // Öğrenciyi buluyoruz
        Student student = studentRepository.getByUserNumber(username);

        // Hikayeyi buluyoruz
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);

        // Öğrencinin, hikaye sahibi olup olmadığını kontrol ediyoruz
        student.getStories().stream()
                .filter(story1 -> story1.equals(story))
                .findFirst()
                .orElseThrow(OwnerStoryException::new);

        StoryDetails storyDetails = storyConverter.toDetails(story, pageable);  // Sayfalama parametresini buraya ekliyoruz

        return new DataResponseMessage<>("Hikaye detayları başarıyla getirildi.", true, storyDetails);
    }

    @Override
    @Transactional
    public ResponseMessage featureUpdate(String username, UUID featureId, String title, MultipartFile file) throws StudentNotFoundException, FeaturedStoryGroupNotFoundException, FeaturedStoryGroupNotAccess, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException {
        Student student = studentRepository.getByUserNumber(username);
        FeaturedStory featuredStory = featuredStoryRepository.findById(featureId).orElseThrow(FeaturedStoryGroupNotFoundException::new);
        if (!featuredStory.getStudent().equals(student)) {
            throw new FeaturedStoryGroupNotAccess();
        }
        if (title != null) {
            featuredStory.setTitle(title);
        }
        if (file != null && !file.isEmpty()) {
          CompletableFuture<String> stringCompletableFuture=mediaUploadService.uploadAndOptimizeMedia(file);

            featuredStory.setCoverPhoto(stringCompletableFuture.join());
        }

        featuredStoryRepository.save(featuredStory);
        return new ResponseMessage("öne çıkarılan hikaye grubu düzenlendi", true);
    }

    @Override
    public DataResponseMessage<FeatureStoryDTO> getFeatureId(String username, UUID featureId) throws StudentNotFoundException, FeaturedStoryGroupNotFoundException, BlockingBetweenStudent, StudentProfilePrivateException {
        Student student = studentRepository.getByUserNumber(username);
        FeaturedStory featuredStory = featuredStoryRepository.findById(featureId).orElseThrow(FeaturedStoryGroupNotFoundException::new);
        Student student1 = featuredStory.getStudent();
        accessStory(student, student1);
        FeatureStoryDTO featureStoryDTO = storyConverter.toFeatureStoryDto(featuredStory);

        return new DataResponseMessage<>("başarılı", true, featureStoryDTO);
    }

    @Override
    public DataResponseMessage<List<FeatureStoryDTO>> getFeaturedStoriesByStudent(String username, Long studentId) throws StudentNotFoundException, BlockingBetweenStudent, StudentProfilePrivateException {
        Student student = studentRepository.getByUserNumber(username);
        Student student1 = studentRepository.findById(studentId).orElseThrow(StudentNotFoundException::new);
        accessStory(student, student1);
        List<FeatureStoryDTO> featureStoryDTOS = student1.getFeaturedStories().stream().map(storyConverter::toFeatureStoryDto).toList();
        return new DataResponseMessage<>("başarılı", true, featureStoryDTOS);
    }

    @Override
    public DataResponseMessage<List<FeatureStoryDTO>> getMyFeaturedStories(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        List<FeatureStoryDTO> featureStoryDTOS = student.getFeaturedStories().stream().map(storyConverter::toFeatureStoryDto).toList();
        return new DataResponseMessage<>("başarılı", true, featureStoryDTOS);
    }

    @Override
    public DataResponseMessage<List<StoryDTO>> archivedStories(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        List<StoryDTO> storyDTOS = student.getArchivedStories().stream().map(storyConverter::toDto).toList();
        return new DataResponseMessage<>("arşiv", true, storyDTOS);
    }

    @Override
    public ResponseMessage deleteArchived(String username, UUID storyId) {
        return null;
    }

    private void accessStory(Student student, Student student1) throws BlockingBetweenStudent, StudentProfilePrivateException {

        if (student.equals(student1)) {
            return;
        }
        boolean blocked = student.getBlocked().stream().anyMatch(b -> b.getBlocked().equals(student1)) ||
                student1.getBlocked().stream().anyMatch(b -> b.getBlocked().equals(student));

        if (blocked) {
            throw new BlockingBetweenStudent();
        }

        if (student1.isPrivate()) {
            boolean isFollowing = student.getFollowing().stream()
                    .anyMatch(f -> f.getFollowed().equals(student1));

            if (!isFollowing) {
                throw new StudentProfilePrivateException();
            }

        }
    }


    @Override
    @Transactional
    public ResponseMessage featureStory(String username, UUID storyId, UUID featuredStoryId)
            throws StudentNotFoundException, StoryNotFoundException, OwnerStoryException, AlreadyFeaturedStoriesException, FeaturedStoryGroupNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);

        if (!student.getStories().contains(story)) {
            throw new OwnerStoryException();
        }
        Optional<FeaturedStory> existingFeaturedGroup = featuredStoryRepository.findFeaturedStoryByStudentAndStory(student, story);
        if (existingFeaturedGroup.isPresent()) {
            throw new AlreadyFeaturedStoriesException();
        }

        FeaturedStory featuredStory;
        if (featuredStoryId != null) {
            featuredStory = featuredStoryRepository.findById(featuredStoryId)
                    .orElseThrow(FeaturedStoryGroupNotFoundException::new);
        } else {
            // Yeni bir FeaturedStory grubu oluştur
            featuredStory = new FeaturedStory();
            featuredStory.setStudent(student);
            featuredStory.setTitle("Yeni Öne Çıkan Hikayeler"); // Varsayılan başlık
            featuredStory.setCreateAt(LocalDateTime.now());
            featuredStory.setCoverPhoto(story.getPhoto()); // Öne çıkan hikayenin kapağı olarak hikayenin fotoğrafı
            featuredStory = featuredStoryRepository.save(featuredStory);
        }

        // Hikayeyi öne çıkan olarak işaretle ve gruba ekle
        story.setFeatured(true);  // Hikaye öne çıkan olarak işaretleniyor
        story.setActive(true);    // Hikaye aktif duruma getirilir
        story.setFeaturedStory(featuredStory);
        // Hikayeyi gruba ekle
        featuredStory.getStories().add(story);  // Hikayeyi FeaturedStory'nin listesine ekle

        // Hem hikayeyi hem de featuredStory'i kaydet
        storyRepository.save(story);  // Hikaye kaydediliyor
        featuredStoryRepository.save(featuredStory);  // FeaturedStory kaydediliyor

        return new ResponseMessage("Hikaye başarıyla öne çıkarılanlara eklendi.", true);
    }


    @Override
    public DataResponseMessage<List<StoryDetails>> getStories(String username, Pageable pageable) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);

        Page<Story> storiesPage = storyRepository.findByStudentAndIsActive(student, true, pageable);

        List<StoryDetails> storyDetails = storiesPage.getContent().stream()
                .filter(Story::getIsActive)
                .map(story -> storyConverter.toDetails(story, pageable))
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Aktif hikayeler başarıyla getirildi.", true, storyDetails);
    }

    @Transactional
    public void archiveExpiredStories() {
        List<Story> expiredStories = storyRepository.findExpiredStories();

        if (expiredStories.isEmpty()) return; // Hiç süresi dolmuş hikaye yoksa işlem yapma

        for (Story story : expiredStories) {
            Student owner = story.getStudent();
            owner.getArchivedStories().add(story); // Arşive ekle
            story.setActive(false);
        }

        // Tüm değişiklikleri tek seferde kaydet
        storyRepository.saveAll(expiredStories);
        studentRepository.saveAll(expiredStories.stream().map(Story::getStudent).distinct().toList());
    }
    @Scheduled(cron = "0 0 * * * ?") // Her saat başında çalışır
    public void scheduledArchiveExpiredStories() {
        archiveExpiredStories();
    }

    @Override
    @Transactional
    public ResponseMessage extendStoryDuration(String username, UUID storyId, int hours)
            throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException, InvalidHourRangeException, FeaturedStoryModificationException {

        // Kullanıcıyı getir
        Student student = studentRepository.getByUserNumber(username);

        // Eğer saat aralığı geçersizse hata fırlat
        if (hours < 1 || hours > 24) {
            throw new InvalidHourRangeException();
        }
        // Kullanıcının hikayelerinden ilgili hikayeyi bul
        Story story = student.getStories().stream()
                .filter(s -> s.getId().equals(storyId))
                .findFirst()
                .orElseThrow(OwnerStoryException::new);

        // Eğer hikaye aktif değilse süre uzatma yapılamaz
        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }

        // Eğer hikaye öne çıkarılmışsa süresi değiştirilemez
        if (story.isFeatured()) {
            throw new FeaturedStoryModificationException();
        }

        // Süreyi uzat
        story.setExpiresAt(story.getExpiresAt().plusHours(hours));

        // Veritabanına kaydet
        storyRepository.save(story);
        studentRepository.save(student);

        return new ResponseMessage("Hikaye süresi başarıyla uzatıldı.", true);
    }


    @Override
    public List<SearchAccountDTO> getStoryViewers(String username, UUID storyId)
            throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException {

        // Kullanıcıyı getir
        Student student = studentRepository.getByUserNumber(username);

        // Kullanıcının hikayelerinden ilgili hikayeyi bul
        Story story = student.getStories().stream()
                .filter(s -> s.getId().equals(storyId))
                .findFirst()
                .orElseThrow(OwnerStoryException::new);

        // Eğer hikaye aktif değilse hata fırlat
        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }

        return story.getViewers().stream()
                .map(viewer -> studentConverter.toSearchAccountDTO(viewer.getStudent())) // Doğru map kullanımı
                .collect(Collectors.toList());
    }


    @Override
    public int getStoryViewCount(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException {
        Student student = studentRepository.getByUserNumber(username);

        // Kullanıcının hikayelerinden ilgili hikayeyi bul
        Story story = student.getStories().stream()
                .filter(s -> s.getId().equals(storyId))
                .findFirst()
                .orElseThrow(OwnerStoryException::new);

        // Eğer hikaye aktif değilse hata fırlat
        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }
        return story.getViewers().size();
    }

    @Override
    public DataResponseMessage<List<StoryDTO>> getPopularStories(String username) throws StudentNotFoundException {
        List<Story> activeStories = storyRepository.findAll().stream()
                .filter(story -> story.getIsActive() && !story.getStudent().isPrivate())
                .toList();

        List<Story> sortedStories = activeStories.stream()
                .sorted(Comparator.comparingLong(Story::getScore).reversed())
                .limit(3)
                .toList();

        List<StoryDTO> popularStories = sortedStories.stream()
                .map(storyConverter::toDto)
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Popüler hikayeler listelendi", true, popularStories);
    }


    @Override
    public DataResponseMessage<List<StoryDTO>> getUserActiveStories(String username, Long userId)
            throws StudentNotFoundException, BlockingBetweenStudent, NotFollowingException {
        Student student = studentRepository.getByUserNumber(username);
        Student student1 = studentRepository.findById(userId).orElseThrow(StudentNotFoundException::new);

        boolean isBlockedByStudent1 = student1.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocker().equals(student));
        boolean isBlockedByStudent = student.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocker().equals(student1));

        if (isBlockedByStudent1 || isBlockedByStudent) {
            throw new BlockingBetweenStudent();
        }

        boolean isFollowing = student.getFollowing().stream()
                .anyMatch(followRelation -> followRelation.getFollower().equals(student1));  // student1 takip ediliyor mu?

        if (!student1.isPrivate() || isFollowing) {
            List<Story> stories = student1.getStories().stream().filter(Story::getIsActive).toList();

            List<StoryDTO> storyDTOS = stories.stream().map(storyConverter::toDto).collect(Collectors.toList());

            return new DataResponseMessage<>("Hikayeler başarıyla listelendi", true, storyDTOS);
        } else {
            throw new NotFollowingException();
        }
    }


    @Override
    public DataResponseMessage<List<CommentDetailsDTO>> getStoryComments(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException {
        Student student = studentRepository.getByUserNumber(username);

        Story story = student.getStories().stream()
                .filter(s -> s.getId().equals(storyId))
                .findFirst()
                .orElseThrow(OwnerStoryException::new);

        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }
        List<Comment> comments = story.getComments();
        List<CommentDetailsDTO> commentDetailsDTOS = comments.stream().map(commentConverter::toDetails).toList();

        return new DataResponseMessage<>("yorumlar", true, commentDetailsDTOS);
    }

    @Override
    @Transactional
    public DataResponseMessage<StoryDTO> viewStory(String username, UUID storyId)
            throws StoryNotFoundException, StoryNotActiveException, StudentNotFoundException, NotFollowingException, BlockingBetweenStudent {
        Student student = studentRepository.getByUserNumber(username);

        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);

        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }

        Student student1 = story.getStudent();

        boolean isBlockedByStudent1 = student1.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocker().equals(student));
        boolean isBlockedByStudent = student.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocker().equals(student1));

        if (isBlockedByStudent1 || isBlockedByStudent) {
            throw new BlockingBetweenStudent();
        }

        boolean isFollowing = student.getFollowing().stream()
                .anyMatch(followRelation -> followRelation.getFollower().equals(student1));

        if (student1.isPrivate() && !isFollowing) {
            throw new NotFollowingException();
        }

        boolean hasViewedBefore = story.getViewers().stream()
                .anyMatch(storyViewer -> storyViewer.getStudent().equals(student));

        if (!hasViewedBefore) {
            StoryViewer storyViewer = new StoryViewer();
            storyViewer.setViewedAt(LocalDateTime.now());
            storyViewer.setStudent(student);
            storyViewer.setStory(story);
            storyViewerRepository.save(storyViewer);
        }

        StoryDTO storyDTO = storyConverter.toDto(story);
        return new DataResponseMessage<>("İçerik başarıyla görüntülendi", true, storyDTO);
    }


    @Override
    public DataResponseMessage<List<LikeDetailsDTO>> getLike(String username, UUID storyId) throws StudentNotFoundException, OwnerStoryException, StoryNotActiveException {
        Student student = studentRepository.getByUserNumber(username);

        Story story = student.getStories().stream()
                .filter(s -> s.getId().equals(storyId))
                .findFirst()
                .orElseThrow(OwnerStoryException::new);

        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }
        List<Like> likes = story.getLikes();
        List<LikeDetailsDTO> likeDetailsDTOS = likes.stream().map(likeConverter::toDetails).toList();
        return new DataResponseMessage<>("beğenenler", true, likeDetailsDTOS);
    }


}
