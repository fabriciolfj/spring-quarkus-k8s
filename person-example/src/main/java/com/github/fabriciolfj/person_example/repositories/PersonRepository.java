package com.github.fabriciolfj.person_example.repositories;

import com.github.fabriciolfj.person_example.entities.Person;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PersonRepository extends JpaRepository<Person, Long> {

    Person finByName(String name);
    List<Person> findByAgeGreaterThan(int age);
}
