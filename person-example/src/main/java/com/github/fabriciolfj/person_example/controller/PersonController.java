package com.github.fabriciolfj.person_example.controller;

import com.github.fabriciolfj.person_example.entities.Person;
import com.github.fabriciolfj.person_example.repositories.PersonRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/persons")
public class PersonController {

    private final PersonRepository personRepository;

    @GetMapping
    public List<Person> getAll() {
        log.info("get all persons");
        return personRepository.findAll();
    }

    @GetMapping("/{id}")
    public Person getById(@PathVariable("id") final Long id) {
        log.info("get by id {}", id);
        return personRepository.findById(id).orElseThrow();
    }

    @GetMapping("/age/{age}")
    public List<Person> getByAgeGreaterThan(@PathVariable("age") int age) {
        log.info("get person by age {}", age);
        return personRepository.findByAgeGreaterThan(age);
    }

    @DeleteMapping("/{id}")
    public void deleteById(@PathVariable("id") final Long id) {
        log.info("delete person by id={}", id);
        personRepository.deleteById(id);
    }

    @PostMapping
    public Person addNew(@RequestBody final Person person) {
        log.info("add new person {}", person);
        return personRepository.save(person);
    }

}
