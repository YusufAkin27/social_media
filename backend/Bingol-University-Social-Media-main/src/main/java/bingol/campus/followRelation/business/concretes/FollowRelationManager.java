package bingol.campus.followRelation.business.concretes;

import bingol.campus.followRelation.business.abstracts.FollowRelationService;
import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.followRelation.core.exceptions.FollowRelationNotFoundException;
import bingol.campus.followRelation.core.exceptions.UnauthorizedAccessException;
import bingol.campus.followRelation.entity.FollowRelation;
import bingol.campus.followRelation.repository.FollowRelationRepository;
import bingol.campus.friendRequest.core.converter.FriendRequestConverter;
import bingol.campus.friendRequest.core.response.FollowedUserDTO;
import bingol.campus.log.business.abstracts.LogService;
import bingol.campus.log.core.request.CreateLogRequest;
import bingol.campus.post.core.converter.PostConverter;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.core.converter.StudentConverter;
import bingol.campus.student.core.response.SearchAccountDTO;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FollowRelationManager implements FollowRelationService {
    private final StudentRepository studentRepository;
    private final FollowRelationRepository followRelationRepository;
    private final FriendRequestConverter friendRequestConverter;
    private final PostConverter postConverter;
    private final StudentConverter studentConverter;
    private final LogService logService;

    @Override
    public DataResponseMessage<List<FollowedUserDTO>> getFollowing(String username, Pageable pageable) throws StudentNotFoundException {
        // Sayfa boyutunu 10 olarak ayarla (size = 10)
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10, pageable.getSort());

        // Öğrenciyi bul
        Student student = studentRepository.getByUserNumber(username);

        // Takip edilen kullanıcıları sayfalı şekilde al
        Page<FollowRelation> followRelations = followRelationRepository.findByFollower(student, pageRequest);

        // Sayfa içeriğindeki takip edilen kullanıcıları DTO'ya dönüştür
        List<FollowedUserDTO> following = followRelations.getContent().stream()
                .filter(followRelation -> followRelation.getFollowed().getIsActive()) // Yalnızca aktif olan takip edilenleri al
                .map(friendRequestConverter::followingToDto)
                .collect(Collectors.toList());

        // Sayfa bilgisi ve içerik ile döndür
        return new DataResponseMessage<>(
                "Takip edilen aktif kullanıcılar listesi",
                true,
                following
        );
    }

    @Override
    public DataResponseMessage<List<FollowedUserDTO>> getFollowers(String username, Pageable pageable) throws StudentNotFoundException {
        // Sayfa boyutunu 10 olarak ayarla (size = 10)
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10, pageable.getSort());

        // Öğrenciyi bul
        Student student = studentRepository.getByUserNumber(username);

        // Takip eden kullanıcıları sayfalı şekilde al
        Page<FollowRelation> followRelations = followRelationRepository.findByFollowed(student, pageRequest);

        // Sayfa içeriğindeki takipçi kullanıcıları DTO'ya dönüştür
        List<FollowedUserDTO> followers = followRelations.getContent().stream()
                .filter(followRelation -> followRelation.getFollower().getIsActive()) // Yalnızca aktif olan takipçileri al
                .map(friendRequestConverter::followersToDto)
                .collect(Collectors.toList());

        // Sayfa bilgisi ve içerik ile döndür
        return new DataResponseMessage<>(
                "Takipçi aktif kullanıcılar listesi",
                true,
                followers
        );
    }



    @Override
    @Transactional
    public ResponseMessage deleteFollowing(String username, Long userId) throws FollowRelationNotFoundException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException {
        // Öğrenci kontrolü
        Student student = studentRepository.getByUserNumber(username);
        if (student == null) {
            throw new StudentNotFoundException();
        }

        // Takip edilen kişi kontrolü
        FollowRelation followRelation = student.getFollowing()
                .stream()
                .filter(relation -> relation.getFollowed().getId().equals(userId))
                .findFirst()
                .orElseThrow(FollowRelationNotFoundException::new);

        // İlişkiyi kaldırma işlemi (örnek)
        student.getFollowing().remove(followRelation);
        studentRepository.save(student);
        followRelationRepository.delete(followRelation);

        CreateLogRequest createLogRequest = new CreateLogRequest();
        createLogRequest.setMessage(student.getUsername() + " seni takipten çıkardı.");
        createLogRequest.setStudentId(followRelation.getFollowed().getId());
        logService.addLog(createLogRequest);

        return new ResponseMessage("Takip edilen kullanıcı başarıyla çıkarıldı.", true);
    }

    @Override
    @Transactional
    public ResponseMessage deleteFollower(String username, Long userId) throws StudentNotFoundException, FollowRelationNotFoundException, StudentDeletedException, StudentNotActiveException {
        // Öğrenci kontrolü
        Student student = studentRepository.getByUserNumber(username);
        if (student == null) {
            throw new StudentNotFoundException();
        }

        // Takipçi kontrolü
        FollowRelation followRelation = student.getFollowers()
                .stream()
                .filter(relation -> relation.getFollower().getId().equals(userId))
                .findFirst()
                .orElseThrow(FollowRelationNotFoundException::new);

        // İlişkiyi kaldırma işlemi (örnek)
        student.getFollowers().remove(followRelation);
        studentRepository.save(student);
        followRelationRepository.delete(followRelation);

        CreateLogRequest createLogRequest = new CreateLogRequest();
        createLogRequest.setMessage(student.getUsername() + " seni takipçilerinden çıkardı.");
        createLogRequest.setStudentId(followRelation.getFollower().getId());
        logService.addLog(createLogRequest);

        return new ResponseMessage("Takipçi başarıyla çıkarıldı.", true);
    }


    @Override
    public DataResponseMessage<List<FollowedUserDTO> > searchFollowers(String username, String query, Pageable pageable) throws StudentNotFoundException {
        // Öğrenci kontrolü
        Student student = studentRepository.getByUserNumber(username);


        // Takipçileri sayfalı olarak al, query parametresine göre filtrele
        Page<FollowRelation> followersPage = followRelationRepository.findByFollowerAndStudentContaining(student, query, pageable);

        // Sayfa içeriğini DTO'ya dönüştür
        List<FollowedUserDTO> matchingFollowers = followersPage.getContent().stream()
                .map(followRelation -> {
                    Student follower = followRelation.getFollower();
                    return friendRequestConverter.followersToDto(followRelation);
                })
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Takipçiler araması tamamlandı.", true, matchingFollowers);
    }

    @Override
    public DataResponseMessage<List<FollowedUserDTO> > searchFollowing(String username, String query, Pageable pageable) throws StudentNotFoundException {
        // Öğrenci kontrolü
        Student student = studentRepository.getByUserNumber(username);

        // Takip edilenleri sayfalı olarak al, query parametresine göre filtrele
        Page<FollowRelation> followingPage = followRelationRepository.findByFollowedAndStudentContaining(student, query, pageable);

        // Sayfa içeriğini DTO'ya dönüştür
        List<FollowedUserDTO> matchingFollowing = followingPage.getContent().stream()
                .map(followRelation -> {
                    Student followed = followRelation.getFollowed();
                    return friendRequestConverter.followingToDto(followRelation);
                })
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Takip edilenler araması tamamlandı.", true, matchingFollowing);
    }


    @Override
    public ResponseMessage getFollowersCount(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        long count = student.getFollowers().stream().count();
        return new ResponseMessage("" + count, true);
    }

    @Override
    public ResponseMessage getFollowingCount(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        long count = student.getFollowing().stream().count();
        return new ResponseMessage("" + count, true);
    }

    @Override
    public DataResponseMessage<List<String>> getCommonFollowers(String username, String username1) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Set<String> benimTakipEttiklerim = student.getFollowing().stream()
                .map(followRelation -> followRelation.getFollowed().getUsername())
                .collect(Collectors.toSet());

        Student student1 = studentRepository.getByUserNumber(username1);
        Set<String> takipcileri = student1.getFollowers().stream()
                .map(followRelation -> followRelation.getFollower().getUsername())
                .collect(Collectors.toSet());

        Set<String> takipEttikleri = student1.getFollowing().stream()
                .map(followRelation -> followRelation.getFollowed().getUsername())
                .collect(Collectors.toSet());

        Set<String> ortakTakipciler = new HashSet<>(benimTakipEttiklerim);
        ortakTakipciler.retainAll(takipcileri);

        Set<String> ortakTakipEdilenler = new HashSet<>(benimTakipEttiklerim);
        ortakTakipEdilenler.retainAll(takipEttikleri);

        ortakTakipciler.addAll(ortakTakipEdilenler);

        return new DataResponseMessage<>("Ortak takipçiler ve takip edilenler", true, new ArrayList<>(ortakTakipciler));
    }


    @Override
    public DataResponseMessage<List<PostDTO>> getFollowingPosts(String username, String username1) throws StudentNotFoundException {
        // Öğrencileri al
        Student student = studentRepository.getByUserNumber(username);
        Student student1 = studentRepository.getByUserNumber(username1);

        boolean isBlocked = student.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocked().equals(student1)) ||
                student1.getBlocked().stream()
                        .anyMatch(blockRelation -> blockRelation.getBlocked().equals(student));

        if (isBlocked) {
            return new DataResponseMessage<>("Engellenmiş durumda, gönderilere erişim yok.", false, new ArrayList<>());
        }

        // Eğer student1'i takip etmiyorsa ya da gönderisi gizliyse, boş bir liste döndür
        boolean isFollowing = student.getFollowing().stream()
                .anyMatch(followRelation -> followRelation.getFollowed().equals(student1));

        // Gizlilik ve takip durumu kontrolü
        if (!isFollowing && student1.isPrivate()) {
            return new DataResponseMessage<>("Gönderiler gizli veya takip edilmiyor", false, new ArrayList<>());
        }

        // Gönderileri al
        List<PostDTO> gönderiler = student1.getPost().stream().map(postConverter::toDto).toList();

        // Sonuçları döndür
        return new DataResponseMessage<>("Gönderiler", true, gönderiler);
    }

    @Override
    public DataResponseMessage<List<SearchAccountDTO>> getUsernameFollowers(String username, String username1)
            throws StudentNotFoundException, UnauthorizedAccessException, BlockingBetweenStudent {

        Student requestingUser = getStudentByUsername(username);
        Student targetUser = getStudentByUsername(username1);

        validateBlocking(requestingUser, targetUser);

        validatePrivacyAndFollowing(requestingUser, targetUser);

        List<SearchAccountDTO> followers = targetUser.getFollowers().stream()
                .map(followRelation -> studentConverter.toSearchAccountDTO(followRelation.getFollower()))
                .toList();

        return new DataResponseMessage<>("Takipçi listesi başarıyla getirildi.", true, followers);
    }

    private Student getStudentByUsername(String username) throws StudentNotFoundException {
        return studentRepository.getByUserNumber(username);
    }

    private void validateBlocking(Student student1, Student student2) throws  BlockingBetweenStudent {
        boolean isBlocked = student1.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocked().equals(student2));

        if (isBlocked) {
            throw new BlockingBetweenStudent();
        }
    }

    private void validatePrivacyAndFollowing(Student requestingUser, Student targetUser) throws UnauthorizedAccessException {
        if (targetUser.isPrivate()) {
            boolean isFollowing = requestingUser.getFollowing().stream()
                    .anyMatch(followRelation -> followRelation.getFollowed().equals(targetUser));
            if (!isFollowing) {
                throw new UnauthorizedAccessException();
            }
        }
    }



    @Override
    public DataResponseMessage<List<SearchAccountDTO>> getUsernameFollowing(String username, String username1) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {

        Student requestingUser = getStudentByUsername(username);
        Student targetUser = getStudentByUsername(username1);

        validateBlocking(requestingUser, targetUser);

        validatePrivacyAndFollowing(requestingUser, targetUser);

        List<SearchAccountDTO> following = targetUser.getFollowing().stream()
                .map(followRelation -> studentConverter.toSearchAccountDTO(followRelation.getFollowed()))
                .toList();

        return new DataResponseMessage<>("Takip edilen kullanıcılar başarıyla getirildi.", true, following);
    }


    @Override
    public DataResponseMessage<List<SearchAccountDTO>> searchInFollowers(String username, String username1, String query)
            throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {

        Student requestingUser = getStudentByUsername(username);
        Student targetUser = getStudentByUsername(username1);

        validateBlocking(requestingUser, targetUser);

        validatePrivacyAndFollowing(requestingUser, targetUser);

        List<SearchAccountDTO> filteredFollowers = targetUser.getFollowers().stream()
                .map(followRelation -> followRelation.getFollower())
                .filter(follower -> follower.getUsername().toLowerCase().contains(query.toLowerCase())) // Kullanıcı adı filtreleme
                .filter(follower -> !isBlocked(requestingUser, follower) && !isBlocked(follower, requestingUser)) // Engelleme kontrolü
                .map(studentConverter::toSearchAccountDTO)
                .toList();

        return new DataResponseMessage<>("Arama sonuçları başarıyla getirildi.", true, filteredFollowers);
    }

    @Override
    public DataResponseMessage<List<SearchAccountDTO>> searchInFollowing(String username, String username1, String query)
            throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {

        Student requestingUser = getStudentByUsername(username);
        Student targetUser = getStudentByUsername(username1);

        validateBlocking(requestingUser, targetUser);

        validatePrivacyAndFollowing(requestingUser, targetUser);

        List<SearchAccountDTO> filteredFollowing = targetUser.getFollowing().stream()
                .map(followRelation -> followRelation.getFollowed())
                .filter(followed -> followed.getUsername().toLowerCase().contains(query.toLowerCase())) // Kullanıcı adı filtreleme
                .filter(followed -> !isBlocked(requestingUser, followed) && !isBlocked(followed, requestingUser)) // Engelleme kontrolü
                .map(studentConverter::toSearchAccountDTO)
                .toList();

        return new DataResponseMessage<>("Arama sonuçları başarıyla getirildi.", true, filteredFollowing);
    }
    private boolean isBlocked(Student student1, Student student2) {
        return student1.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocked().equals(student2));
    }

}
