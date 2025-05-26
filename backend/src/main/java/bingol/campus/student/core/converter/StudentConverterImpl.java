package bingol.campus.student.core.converter;

import bingol.campus.followRelation.business.abstracts.FollowRelationService;
import bingol.campus.post.core.converter.PostConverter;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.security.entity.Role;

import bingol.campus.story.core.response.FeatureStoryDTO;
import bingol.campus.story.core.response.StoryDTO;
import bingol.campus.story.entity.FeaturedStory;
import bingol.campus.story.entity.Story;
import bingol.campus.student.core.response.*;
import bingol.campus.student.core.request.CreateStudentRequest;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class StudentConverterImpl implements StudentConverter {
    private final PasswordEncoder passwordEncoder;
    private final PostConverter postConverter;
    @Override
    public Student createToStudent(CreateStudentRequest createStudentRequest) {

        Student student = new Student();
        student.setPrivate(false);
        student.setCreatedAt(LocalDateTime.now());
        student.setUserNumber(createStudentRequest.getUsername()); // kullanıcı adı
        student.setPassword(passwordEncoder.encode(createStudentRequest.getPassword())); // Şifreyi şifreliyoruz
        student.setRoles(Set.of(Role.STUDENT, Role.ADMIN)); // Rolü belirliyoruz
        student.setGender(createStudentRequest.getGender()); // Cinsiyeti alıyoruz
        student.setEmail(createStudentRequest.getEmail()); // E-posta adresini alıyoruz
        student.setFaculty(createStudentRequest.getFaculty()); // Fakülteyi alıyoruz
        student.setBirthDate(createStudentRequest.getBirthDate()); // Doğum tarihini alıyoruz
        student.setIsDeleted(false); // Varsayılan olarak silinmiş değil
        student.setDepartment(createStudentRequest.getDepartment()); // Bölümü alıyoruz
        student.setBio(String.format("%s , %s bölümünde %s olarak öğrenim görüyorum.", createStudentRequest.getFaculty().getDisplayName(), createStudentRequest.getDepartment().getDisplayName(), createStudentRequest.getGrade().getDisplayName()));
        student.setFirstName(createStudentRequest.getFirstName()); // Adı alıyoruz
        student.setGrade(createStudentRequest.getGrade()); // Sınıfı alıyoruz
        student.setProfilePhoto("https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg");
        student.setMobilePhone(createStudentRequest.getMobilePhone()); // Telefonu alıyoruz
        student.setIsActive(true);
        student.setUsername(createStudentRequest.getUsername());
        student.setLastName(createStudentRequest.getLastName()); // Soyadı alıyoruz
        return student;
    }


    @Override
    public StudentDTO toDto(Student student) {
        if (student == null) {
            return null;
        }

        StudentDTO studentDto = new StudentDTO();
        studentDto.setUserId(student.getId());
        studentDto.setFirstName(student.getFirstName());
        studentDto.setLastName(student.getLastName());
        studentDto.setTcIdentityNumber(student.getUsername());
        studentDto.setEmail(student.getEmail());
        studentDto.setMobilePhone(student.getMobilePhone());
        studentDto.setUsername(student.getUsername());
        studentDto.setBirthDate(student.getBirthDate());
        studentDto.setGender(student.getGender());
        studentDto.setFaculty(student.getFaculty());
        studentDto.setDepartment(student.getDepartment());
        studentDto.setGrade(student.getGrade());
        studentDto.setProfilePhoto(student.getProfilePhoto());
        studentDto.setIsActive(student.getIsActive());
        studentDto.setIsDeleted(student.getIsDeleted());
        studentDto.setPrivate(student.isPrivate());
        studentDto.setBiography(student.getBio());
        studentDto.setPopularityScore(student.getPopularityScore());
        studentDto.setFollower(student.getFollowers() == null ? 0 : student.getFollowers().size());
        studentDto.setFollowing(student.getFollowing() == null ? 0 : student.getFollowing().size());
        studentDto.setBlock(student.getBlocked() == null ? 0 : student.getBlocked().size());
        studentDto.setComments(student.getComments() == null ? 0 : student.getComments().size());
        studentDto.setLikedContents(student.getLikes() == null ? 0 : student.getLikes().size());
        return studentDto;
    }

    @Override
    public PublicAccountDetails publicAccountDto(Student student) {
        PublicAccountDetails publicAccountDetails = PublicAccountDetails.builder()
                .userId(student.getId())
                .username(student.getUsername())
                .fullName(student.getFirstName() + " " + student.getLastName())
                .profilePhoto(student.getProfilePhoto())
                .bio(student.getBio())
                .popularityScore(student.getPopularityScore())
                .isPrivate(student.isPrivate())
                .followerCount(student.getFollowers().size())
                .postCount(student.getPost().size())
                .followingCount(student.getFollowing().size())
                .featuredStories(student.getFeaturedStories().stream()
                        .map(this::convertToFeatureStoryDTO)
                        .limit(3)
                        .toList())
                .posts(student.getPost().stream()
                        .map(postConverter::toDto)
                        .limit(3)
                        .toList())
                .stories(student.getStories().stream()
                        .map(this::convertToStoryDTO)
                        .limit(3)
                        .toList())
                .build();

        return publicAccountDetails;
    }

    private StoryDTO convertToStoryDTO(Story story) {
        StoryDTO storyDTO = new StoryDTO();

        storyDTO.setUsername(story.getStudent().getUsername());
        storyDTO.setProfilePhoto(story.getStudent().getProfilePhoto());
        storyDTO.setUserId(story.getStudent().getId());
        storyDTO.setPhoto(story.getPhoto());
        storyDTO.setStoryId(story.getId());

        return storyDTO;
    }


    private FeatureStoryDTO convertToFeatureStoryDTO(FeaturedStory featuredStory) {
        // FeaturedStory nesnesinden gerekli bilgileri alarak FeatureStoryDTO oluşturuyoruz
        return FeatureStoryDTO.builder()
                .featureStoryId(featuredStory.getId()) // FeaturedStory'nin ID'si
                .title(featuredStory.getTitle()) // Başlık
                .coverPhoto(featuredStory.getCoverPhoto()) // Kapak fotoğrafı
                .storyDTOS(featuredStory.getStories().stream()
                        .map(this::convertToStoryDTO) // Hikayeleri dönüştür
                        .collect(Collectors.toList())) // StoryDTO'ları liste halinde al
                .build();
    }


    @Override
    public PrivateAccountDetails privateAccountDto(Student student) {
        return PrivateAccountDetails.builder()
                .id(student.getId())
                .username(student.getUsername())
                .profilePhoto(student.getProfilePhoto())
                .bio(student.getBio())
                .followingCount(student.getFollowing().size())
                .followerCount(student.getFollowers().size())
                .postCount(student.getPost().size())
                .isPrivate(student.isPrivate())
                .popularityScore(student.getPopularityScore())
                .build();
    }

    @Override
    public SearchAccountDTO toSearchAccountDTO(Student student) {
        return SearchAccountDTO.builder()
                .fullName(student.getFirstName() + " " + student.getLastName())
                .id(student.getId())
                .profilePhoto(student.getProfilePhoto())
                .username(student.getUsername())
                .build();
    }




}
